# scpr-apps

Recipes for SCPR applications

## Testing

Test with (Test Kitchen)[https://kitchen.ci/], e.g.,

```
kitchen converge
kitchen verify
```

You will need Test Kitchen and Docker installed.

## Deploying changes to servers:

1. bump the version in metadata.rb
1. `berks install`
1. `berks upload`