# S3gw UI

User interface for the `s3gw`.

## Installation

Run `npm ci` to install the necessary node modules.

## Development server

Run `ng serve` for a dev server. Navigate to `http://localhost:4200/`. The app
will automatically reload if you change any of the source files. Make sure the
`proxy.conf.json` file exists and is configured to access your `s3gw`
installation.

### Connect to a K3s setup

If you want to connect the user interface to a
[K3s setup](../s3gw-with-k8s-k3s/#k3s-with-longhorn), use the following
`proxy.conf.json` file.

```json
{
  "/admin/user": {
    "target": "https://s3gw.local",
    "secure": false,
    "changeOrigin": true
  },
  "/admin/metadata/user": {
    "target": "https://s3gw.local",
    "secure": false,
    "changeOrigin": true
  },
  "/admin/bucket": {
    "target": "https://s3gw.local",
    "secure": false,
    "changeOrigin": true
  },
  "http://localhost:4200": {
    "target": "https://s3gw.local",
    "secure": false,
    "changeOrigin": true
  }
}
```

## Beautify and linting code

Run `npm run fix` to beautify and lint the source code.

## Build

Run `ng build` to build the project. The build artifacts will be stored in the
`dist/` directory.

## Running unit tests

Run `ng test:ci` to execute the unit tests.
