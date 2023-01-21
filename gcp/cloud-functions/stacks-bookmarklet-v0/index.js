"use strict";

// Docs
//  - See: https://paper.dropbox.com/doc/stacks-Stacks-Docs--BxK9ZwsdYG37c406XDaV_~03Ag-nSa07kYadCs7VOh27MlmM
//  - Good: https://developer.apple.com/documentation/cloudkitjs
//  - Good: https://cloudkitjs.vercel.app/

// TODO How to fetch all tags within cloutkit data size limits?
//  - https://developer.apple.com/documentation/cloudkitjs/cloudkit/database/1628596-performquery
//  - https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/PropertyMetrics.html#//apple_ref/doc/uid/TP40015240-CH23
//    - Max 200 records per response
//    - Max 1MB per record
//  - Approach v1
//    - Fetch top 200 tags by num pins
//    - This will mean that infrequent tags can't auto-complete in the bookmarklet
//    - Maybe that's ok? They will all be available for auto-complete in the real app, at least
//  - Approach v2
//    - Pack multiple tags per record

// Imports
const functions = require('@google-cloud/functions-framework');

// Utils
const json       = x => JSON.stringify(x);
const jsonPretty = x => JSON.stringify(x, null, 2);

// Constants
const ckConfigContainer = {
  containerIdentifier: 'iCloud.org.jdanbrown.stacks',
  apiToken: process.env.CLOUDKIT_API_TOKEN,
  environment: 'development', // XXX Dev
  // environment: 'production', // TODO
};

// Mimic pinboard bookmarklet's request schema:
//  - https://pinboard.in/howto/
functions.http('bookmarklet', (req, rep) => {
  try {

    rep.send(`
      <!doctype html>
      <html>
        <head>

          <!-- Prevent favicon requests to reduce noise in server logs -->
          <link rel="icon" href="data:," />

          <!-- https://developer.apple.com/documentation/cloudkitjs -->
          <script src="https://cdn.apple-cloudkit.com/ck/2/cloudkit.js"></script>

        </head>
        <body>

          <pre>
            [DEBUG]
            - new Date().toISOString(): ${new Date().toISOString()}

            - Object.keys(req): ${Object.keys(req)}
            - Object.keys(rep): ${Object.keys(rep)}

            - req.method: ${req.method}
            - req.url: ${req.url}
            - req.baseUrl: ${req.baseUrl}
            - req.originalUrl: ${req.originalUrl}
            - json(req.query): ${json(req.query)}
            - json(req.params): ${json(req.params)}
            - json(req.body): ${json(req.body)}

            - req.query.url: ${req.query.url}
            - req.query.title: ${req.query.title}
            - req.query.description: ${req.query.description}

          </pre>

          <div>
            <div id="apple-auth-signin-button"></div>
            <div id="apple-auth-signout-button"></div>
            <div id="apple-auth-user-identity"></div>
            <div id="apple-auth-error" style="background: #fcc"></div>
            <div id="pin-editor"></div>
          </div>

          <script type="module">
            // Use type="module" for top-level await
            //  - https://stackoverflow.com/questions/69777806/async-await-inside-script-api-call-with-fetch-doesnt-return-result
            //  - https://developer.mozilla.org/en-US/docs/Web/JavaScript/Guide/Modules#top_level_await
            //  - https://developer.mozilla.org/en-US/docs/Web/HTML/Element/script/type

            "use strict";

            // Params
            const ckConfigContainer = ${json(ckConfigContainer)};
            const query = ${json(req.query)};

            // Utils
            window.json       = x => JSON.stringify(x);
            window.jsonPretty = x => JSON.stringify(x, null, 2);

            // Configure
            CloudKit.configure({
              // https://developer.apple.com/documentation/cloudkitjs/cloudkit/cloudkitconfig
              services: {
                logger: window.console,
              },
              containers: [{
                // https://developer.apple.com/documentation/cloudkitjs/cloudkit/containerconfig
                containerIdentifier: ckConfigContainer.containerIdentifier,
                environment:         ckConfigContainer.environment,
                apiTokenAuth: {
                  apiToken:      ckConfigContainer.apiToken,
                  persist:       true,
                  signInButton:  {id: 'apple-auth-signin-button'},
                  signOutButton: {id: 'apple-auth-signout-button'},
                },
              }],
            });

            const container = CloudKit.getDefaultContainer();
            console.log('[main]', container.toString(), {container});
            window.container = container; // XXX Debug

            const privateDB = container.privateCloudDatabase;
            console.log('[main]', privateDB.toString(), {privateDB});
            window.privateDB = privateDB; // XXX Debug

            // Auth
            //  - https://cloudkitjs.vercel.app/#authentication
            //  - https://developer.apple.com/documentation/cloudkitjs/cloudkit/container/1628564-setupauth
            function onSignin(userIdentity) {
              console.log('[onSignin]', {userIdentity});
              showAuth({userIdentity, ckError: null});
              container.whenUserSignsOut()
                .then(onSignout);
              loadQuery(query);
            }
            function onSignout(ckError) {
              showAuth({userIdentity: null, ckError}); // ckError might be null
              container.whenUserSignsIn()
                .then(onSignin)
                .catch(onSignout);
              loadQuery(null);
            }
            function showAuth({userIdentity, ckError}) {
              console.log('[showAuth]', {userIdentity, ckError});
              document.getElementById('apple-auth-user-identity').textContent = (
                userIdentity === null ? null : (
                  'User: ' + (userIdentity.lookupInfo?.emailAddress || userIdentity.userRecordName)
                  // TODO lookupInfo is null in development -- maybe it's populated in production?
                )
              );
              document.getElementById('apple-auth-error').textContent = (
                ckError && 'Error: ' + ckError.ckErrorCode + ': ' + ckError.reason
              );
            }
            const userIdentity = await container.setUpAuth()
              .catch(onSignout);
            if (userIdentity) {
              onSignin(userIdentity);
            } else {
              onSignout(null);
            }

            async function loadQuery(query) {
              console.log('[loadQuery]', {query});

              if (query === null) {
                document.getElementById('pin-editor').textContent = '';
                return;
              }

              // Query: Utils
              async function queryRecords(req) {
                console.log('[queryRecords]', {req});
                const records = [];
                var rep = null;
                while (true) {
                  // https://developer.apple.com/documentation/cloudkitjs/cloudkit/database/1628596-performquery
                  //  - Max resultsLimit is 200 (which is also the default)
                  rep = await privateDB.performQuery(rep || req);
                  console.log('[queryRecords]', {rep});
                  if (rep.hasErrors) {
                    throw rep.errors[0];
                  }
                  records.push(...rep.records);
                  if (!rep.moreComing) {
                    break;
                  }
                }
                console.log('[queryRecords]', {records});
                return records;
              }

              // Query: All pins
              const allPinsRecords = await queryRecords({
                recordType: 'CD_CorePin',
              });
              console.log('[main]', {allPinsRecords});
              window.allPinsRecords = allPinsRecords; // XXX Debug

              // Query: This pin
              const thisPinRecords = await queryRecords({
                recordType: 'CD_CorePin',
                filterBy: [{
                  fieldName: 'CD_url',
                  comparator: 'EQUALS',
                  fieldValue: { value: query.url },
                }],
              });
              console.log('[main]', {thisPinRecords});
              window.thisPinRecords = thisPinRecords; // XXX Debug
              const [thisPinRecord] = thisPinRecords;
              window.thisPinRecord = thisPinRecord; // XXX Debug

              // Pin editor
              document.getElementById('pin-editor').style.whiteSpace = 'pre'
              document.getElementById('pin-editor').textContent = jsonPretty(thisPinRecord.fields);

            }

          </script>

        </body>
      </html>
    `);

  } catch (e) {
    console.error('Uncaught exception:', e);
    res.status(500).send(`Uncaught exception: ${e}`);
  }
});
