Geographic Twitter visualisation server

### Configuration

Five environment variables must be set:

```
SENTIMENT_SERVER_HOSTNAME
```
This is the hostname or IP address of a server running the code that can be found at
[this repo](https://github.com/ConorBrady/stanford-nlp-sentiment-api). This is
required for both visualisations.

```
TW_KEY
TW_SECRET
```
These are required for the `/live` endpoint. An app needs to be set up in the
Twitter developer portal and the credentials set to these variables.

```
GRAISEARCH_USERNAME
GRAISEARCH_PASSWORD
```

These are required for the '/scenario' endpoint, they must be valid credentials for read
access for the dataset on the server `graisearch.scss.tcd.ie`

### Deployment

The app is capable of deployment on Heroku's cedar stack with a git push.

Alternatively the app requires rubygems to be installed. You can then run
`bundle install` from the root directory and rubygems will install all
dependancies. The app can then be launced with `rackup -p :port_number`

### Features

This app uses Mapbox, Audiolet, Twitter and the Stanford CoreNLP Toolkit to
visualise and synthesize music to tweets and their sentiment over two settings.
[Live over San Fransisco](http://sentiment-rain.conorbrady.com/live)
and over the course of
[the Dublin Marathon in 2014](http://sentiment-rain.conorbrady.com/scenario).
