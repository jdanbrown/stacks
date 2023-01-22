# Docs
- See https://paper.dropbox.com/doc/stacks-Stacks-Docs--BxK9ZwsdYG37c406XDaV_~03Ag-nSa07kYadCs7VOh27MlmM

# Run locally
```sh
# Copy CLOUDKIT_API_TOKEN from:
# - https://icloud.developer.apple.com/dashboard/database/teams/6S8S88RYPG/containers/iCloud.org.jdanbrown.stacks/environments/DEVELOPMENT/tokens
CLOUDKIT_API_TOKEN=... CLOUDKIT_ENVIRONMENT=development npx @google-cloud/functions-framework --target=bookmarklet
```

# Deploy cloud function (manual)
- Create an api key in CloudKit
  - https://icloud.developer.apple.com/dashboard/database/teams/6S8S88RYPG/containers/iCloud.org.jdanbrown.stacks/environments/DEVELOPMENT/tokens
  - https://icloud.developer.apple.com/dashboard/database/teams/6S8S88RYPG/containers/iCloud.org.jdanbrown.stacks/environments/PRODUCTION/tokens
- Create a secret in Secret Manager
  - https://console.cloud.google.com/security/secret-manager
  - https://console.cloud.google.com/security/secret-manager/secret/cloudkit-api-token-iCloud-org-jdanbrown-stacks-bookmarklet-v0
- Create a Cloud Function
  - https://console.cloud.google.com/functions
  - https://console.cloud.google.com/functions/details/us-central1/stacks-bookmarklet-v0
  - Reference the secret
    - "1. Configuration" -> "Runtime, build, connections and security settings" -> "Security and image repo"
  - Upload/paste the code
    - "2. Code"

# Deploy domain name (stacks.pub)
- Register domain
  - https://domains.google.com/registrar/stacks.pub
- Point domain name at Cloud Function
  - Create mapping: https://console.cloud.google.com/run/domains?project=stacks-375322
    - Docs: https://cloud.google.com/run/docs/mapping-custom-domains
    - Three dots → DNS records
  - Set DNS records: https://domains.google.com/registrar/stacks.pub/dns
