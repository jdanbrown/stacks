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
//    - This will mean that infrequent tags can't autocomplete in the bookmarklet
//    - Maybe that's ok? They will all be available for autocomplete in the real app, at least
//  - Approach v2
//    - Pack multiple tags per record

// Imports
const functions = require('@google-cloud/functions-framework');
const express = require('express');

// Utils
const json       = x => JSON.stringify(x);
const jsonPretty = x => JSON.stringify(x, null, 2);

// Constants
const ckConfigContainer = {
  containerIdentifier: 'iCloud.org.jdanbrown.stacks',
  apiToken: process.env.CLOUDKIT_API_TOKEN,
  environment: process.env.CLOUDKIT_ENVIRONMENT,
};

// Docs
//  - https://medium.com/google-cloud/express-routing-with-google-cloud-functions-36fb55885c68
//  - https://developer.mozilla.org/en-US/docs/Learn/Server-side/Express_Nodejs/routes
const app = express();
exports.bookmarklet = app; // Entrypoint (name is configured in the Cloud Functions deploy)

app.get('/', (req, rep) => {
  try {

    rep.send(`
      <!doctype html>
      <html>
        <head>

          <!-- Black-hole favicon requests to reduce noise in server logs -->
          <link rel="icon" href="data:," />

          <!-- Docs: https://developer.apple.com/documentation/cloudkitjs -->
          <script src="https://cdn.apple-cloudkit.com/ck/2/cloudkit.js"></script>

          <!-- Docs: https://lodash.com/ -->
          <!--  - src url: https://www.jsdelivr.com/package/npm/lodash -->
          <script src="https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.min.js"></script>

          <!-- Docs: https://api.jquery.com/ -->
          <!--  - src url: https://releases.jquery.com/ -->
          <script src="https://code.jquery.com/jquery-3.6.3.min.js"></script>

          <!-- Docs: https://pieroxy.net/blog/pages/lz-string/index.html -->
          <!--  - src url: https://cdnjs.com/libraries/lz-string -->
          <!-- <script src="https://cdnjs.cloudflare.com/ajax/libs/lz-string/1.4.4/lz-string.min.js"></script> -->

          <!-- Docs: https://localforage.github.io/localForage/ -->
          <!--  - More docs: https://github.com/localForage/localForage -->
          <!--  - src url: https://cdnjs.com/libraries/localforage -->
          <script src="https://cdnjs.cloudflare.com/ajax/libs/localforage/1.10.0/localforage.min.js"></script>

        </head>
        <body>

          <!-- Utils -->
          <script>
            "use strict";

            // lodash
            _.pipe = _.thru // More canonical name (I never remember the name of .thru)

            // Utils
            window.json       = x => JSON.stringify(x);
            window.jsonPretty = x => JSON.stringify(x, null, 2);

            function assert(condition, msg) {
              if (!condition) {
                throw new Error('Assertion failed: ' + msg);
              }
            }

            function only(xs) {
              if (xs.length != 1) {
                console.error('[only] Expected 1 element, got ' + xs.length, {xs});
                throw new Error('Expected 1 element, got ' + xs.length);
              }
              return xs[0];
            }

            async function performQuery(db, req, options = undefined) {
              console.log('[performQuery]', {db, req, options});
              // Docs: https://developer.apple.com/documentation/cloudkitjs/cloudkit/database/1628596-performquery
              return await db.performQuery(req, options);
            }

            // NOTE This pagination never fetches more than resultsLimit records (default/max: 200)
            //  - Use queryRecordsAll if you want >200 records
            //  - See comment in queryRecordsAll for notes on what happens instead
            async function queryRecords(db, req) {
              console.log('[queryRecords]', {req});
              const records = [];
              var rep = null;
              while (true) {
                // https://developer.apple.com/documentation/cloudkitjs/cloudkit/database/1628596-performquery
                //  - Max resultsLimit is 200 (which is also the default)
                rep = await performQuery(db, rep || req);
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

            // Like queryRecords but manually paginate all results
            //  - It _seems_ like rep.moreComing + performQuery(rep) would do this for us, but when I tried it out it
            //    always gave me resultsLimit records (default/max: 200) in the first response, with moreComing=true,
            //    and then the second response was always 0 records (using functions-framework 3.1.3)
            //  - So I gave up on that approach and instead do pagination manually to allow querying >200 records
            //  - Docs
            //    - https://developer.apple.com/documentation/cloudkitjs/cloudkit/query
            //    - https://developer.apple.com/documentation/cloudkitjs/cloudkit/database/1628596-performquery
            //    - https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/PropertyMetrics.html#//apple_ref/doc/uid/TP40015240-CH23
            async function queryRecordsAll(db, {recordType, sortByAscending, lastSortByValue}) {
              console.log('[queryRecordsAll] Start', {recordType, sortByAscending, lastSortByValue});
              const resultsLimit = 200;
              var allRecords = [];
              var batch = 1;
              while (true) {
                // https://developer.apple.com/documentation/cloudkitjs/cloudkit/database/1628596-performquery
                //  - Max resultsLimit is 200 (which is also the default)
                const rep = await performQuery(db, {
                  recordType,
                  sortBy: {
                    fieldName: sortByAscending,
                    ascending: true,
                  },
                  filterBy: lastSortByValue && {
                    // Docs
                    //  - https://cloudkitjs.vercel.app/#public-query
                    //  - https://developer.apple.com/documentation/cloudkitjs/cloudkit/queryfiltercomparator
                    //  - https://developer.apple.com/documentation/cloudkit/ckquery
                    //  - https://developer.apple.com/library/archive/documentation/DataManagement/Conceptual/CloudKitWebServicesReference/QueryingRecords.html#//apple_ref/doc/uid/TP40015240-CH5
                    fieldName: sortByAscending,
                    comparator: 'GREATER_THAN',
                    fieldValue: { value: lastSortByValue },
                  },
                }, {
                  resultsLimit,
                });
                console.log('[queryRecordsAll] Got rep', {batch, records: rep.records, rep});
                if (rep.hasErrors) {
                  throw rep.errors[0];
                }
                const batchRecords = _.sortBy(rep.records, x => x.fields[sortByAscending].value);
                allRecords.push(...batchRecords);
                lastSortByValue = !_.isEmpty(batchRecords) && _.last(batchRecords).fields[sortByAscending].value;
                console.log('[queryRecordsAll] Got records', {batch, lastSortByValue, batchRecords, allRecords});
                if (rep.records.length < resultsLimit) {
                  assert(!rep.moreComing, 'Expected no more results, got: rep.moreComing[' + rep.moreComing + ']');
                  break;
                }
                batch += 1;
              }
              assert(_.isEqual(allRecords, _.sortBy(allRecords, x => x.fields[sortByAscending].value)));
              console.log('[queryRecordsAll] Done', {allRecords});
              return allRecords;
            }

            // Returns null if deleted=true
            // Adds ._record property to recover the input record
            function recordToFields(record) {
              if (record.deleted) {
                return null;
              } else {
                const fields = Object.create({
                  get _record() { return record; },
                });
                _.assign(fields, _.mapValues(record.fields, x => x.value));
                return fields
              }
            }

            // Omits elements with deleted=true
            // Adds ._record properties to recover each input record
            function recordsToFields(records) {
              return records
                .map(recordToFields)
                .filter(x => x !== null);
            }

          </script>

          <style>
            #tags-list,
            #pins-list {
              padding: 2em 0em;
            }
            .tag {
              display: inline-flex;
              padding-right: 2ex;
            }
            .pin {
              white-space: pre;
            }
          </style>

          <!-- Debug -->
          <!--
          <pre style="white-space: pre-line">
            [DEBUG]
            - new Date().toISOString(): ${new Date().toISOString()}
            - Object.keys(req): ${Object.keys(req)}
            - Object.keys(rep): ${Object.keys(rep)}
            - req.method: ${req.method}
            - req.url: ${req.url}
            - req.baseUrl: ${req.baseUrl}
            - req.originalUrl: ${req.originalUrl}
            - json(req.route): ${json(req.route)}
            - json(req.query): ${json(req.query)}
            - json(req.params): ${json(req.params)}
            - json(req.body): ${json(req.body)}
            - req.query.url: ${req.query.url}
            - req.query.title: ${req.query.title}
            - req.query.description: ${req.query.description}
          </pre>
          <!-- -->

          <!-- Body -->
          <div>
            <div id="apple-auth-signin-button"></div>
            <div id="apple-auth-signout-button"></div>
            <div id="apple-auth-user-identity"></div>
            <div id="apple-auth-error" style="background: #fcc"></div>
            <div id="pin-editor"></div>
            <div id="tags-list"></div>
            <div id="pins-list"></div>
          </div>

          <!-- Main -->
          <script type="module">
            "use strict";

            // Params
            const ckConfigContainer = ${json(ckConfigContainer)};
            const urlQuery = ${json(req.query)};

            // Init
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
            const privateDB = container.privateCloudDatabase;
            console.log('[main]', {container, privateDB});
            console.log('[main]', container.toString());
            console.log('[main]', privateDB.toString());
            _.assign(window, {container, privateDB}); // Debug

            // Auth
            //  - https://cloudkitjs.vercel.app/#authentication
            //  - https://developer.apple.com/documentation/cloudkitjs/cloudkit/container/1628564-setupauth
            function onSignin(userIdentity) {
              console.log('[onSignin]', {userIdentity});
              showAuth({userIdentity, ckError: null});
              container.whenUserSignsOut()
                .then(onSignout);
              showBody({user: userIdentity, urlQuery});
            }
            function onSignout(ckError) {
              showAuth({userIdentity: null, ckError}); // ckError might be null
              container.whenUserSignsIn()
                .then(onSignin)
                .catch(onSignout);
              showBody({user: null, urlQuery: null});
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

            async function showBody({user, urlQuery}) {
              console.log('[showBody]', {user, urlQuery});
              // If not logged in, show empty body here and let auth show the signin button
              if (user === null) {
                document.getElementById('pin-editor').textContent = '';
                return;
              } else {
                // If urlQuery.url, show the pin editor
                if (urlQuery.url) {
                  await showPinEditor(urlQuery);
                }
                // Always show all pins/tags
                await showPinsAndTags(urlQuery);
              }
            }

            // Mimic pinboard's bookmarklet request schema:
            //  - https://pinboard.in/howto/
            async function showPinEditor(urlQuery) {

              // Query the requested pin
              //  - Query the requested pin sync (to populate form) + all pins async (to populate tags for autocomplete)
              const _pinRecord = only(
                await queryRecords(privateDB, {
                  recordType: 'CD_CorePin',
                  filterBy: [{
                    fieldName: 'CD_url',
                    comparator: 'EQUALS',
                    fieldValue: { value: urlQuery.url },
                  }],
                })
              );
              const pin = recordToFields(_pinRecord);
              console.log('[main]', {pin, _pinRecord});
              _.assign(window, {pin, _pinRecord}); // Debug

              // Pin editor
              document.getElementById('pin-editor').style.whiteSpace = 'pre'
              document.getElementById('pin-editor').textContent = jsonPretty(pin);

              // Mimic pinboard's form
              /*
              Stacks — user — logout
              URL: [input]
              Title: [input]
              Description: [textarea, 4 lines]
              Tags: [input, w/ autocomplete]
              Unread: [checkbox]
              [Cancel] [Save]
              List of all tags (horizontal paragraph flow w/ line wrapping)
              */

            }

            async function queryAllPins() {
              // Read cache
              const cacheKey = 'cache_queryAllPins';
              const cachedPins = await localforage.getItem(cacheKey) || [];
              console.log('[queryAllPins]', {cacheKey, cachedPins});
              // Query
              const sortByAscending = 'CD_modifiedAt';
              const lastSortByValue = _.isEmpty(cachedPins) ? null : _.last(cachedPins)[sortByAscending];
              console.log('[queryAllPins]', {lastSortByValue});
              const _pinsRecords = await queryRecordsAll(privateDB, {
                recordType: 'CD_CorePin',
                sortByAscending, // Old to new, so that local caching can do incremental watermarking
                lastSortByValue, // Query only records newer than local cache
              });
              const pins = cachedPins.concat(recordsToFields(_pinsRecords));
              // Write cache
              await localforage.setItem(cacheKey, pins);
              // Done
              console.log('[queryAllPins]', {pins, _pinsRecords});
              return [pins, _pinsRecords];
            }

            // Inspired by pinboard's home page
            //  - https://pinboard.in/
            async function showPinsAndTags(
              urlQuery, // Not currently used
            ) {

              // Query all pins
              const [pins, _pinsRecords] = await queryAllPins();
              console.log('[main]', {pins, _pinsRecords});
              _.assign(window, {pins, _pinsRecords}); // Debug

              // Extract tags from all pins
              const tags = _(pins)
                .map(pin => pin.CD_tags)
                .flatMap(tags => _.split(tags, ' ').filter(x => x !== ''))
                .countBy()
                .toPairs()
                .sortBy(([x, n]) => -n)
                .value();
              console.log('[main]', {tags});
              _.assign(window, {tags}); // Debug

              // Tags list
              $('#tags-list').append(
                tags.map(([tag, n]) => $('<div class="tag">').text(tag))
              );

              // Pins list
              $('#pins-list').append(
                _(pins)
                .reverse()
                .map(pin => $('<div class="pin">').text(jsonPretty({
                  modifiedAt: new Date(pin.CD_modifiedAt).toISOString(),
                  ...pin,
                })))
                .value()
              );

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
