# TzServer

## Deprecation Notice

Note that Nanobox has been acquired by DigitalOcean. Their new, integrated service won't support Elixir initially. They have committed to continue supporting the existing service until ~August 2020. This service will need to be deployed to a cloud provider or ported to a different technology stack before the deprecation date.

## How to Deploy

1. Install [Nanobox Desktop](https://dashboard.nanobox.io/download)
2. Checkout the code.
3. `cd` to your code.
4. Run the following:

```bash
nanobox remote add tzserver
nanobox evar add PORT=8080
nanobox deploy
```

The environment variables should only need to be set the first time.
