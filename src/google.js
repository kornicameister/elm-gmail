const clientCredentials = require('../client_id.json')['web'];

export function load(isSignedInCallback) {
  gapi.load('client:auth2', () => initClient(isSignedInCallback));
}

export function signIn() {
  gapi.auth2.getAuthInstance().signIn();
}

export function signOut() {
  gapi.auth2.getAuthInstance().signOut();
}

export function getUser() {
  const auth = gapi.auth2.getAuthInstance();
  const isSignedIn = auth.isSignedIn.get();
  if (!isSignedIn) {
    return null;
  } else {
    const user = auth.currentUser.get();
    const profile = user.getBasicProfile();
    const authResponse = user.getAuthResponse();

    const data = {
      'name': profile.getName(),
      'email': profile.getEmail(),
      'imageUrl': profile.getImageUrl(),
      'accessToken': authResponse['access_token'],
    };

    return data;
  }
}

function initClient(isSignedInCallback) {
  gapi.client.init({
    clientId: clientCredentials['client_id'],
    discoveryDocs: ["https://www.googleapis.com/discovery/v1/apis/gmail/v1/rest"],
    scope: 'https://www.googleapis.com/auth/gmail.readonly'
  }).then(function () {
    gapi.auth2.getAuthInstance().isSignedIn.listen(isSignedInCallback);
    isSignedInCallback(gapi.auth2.getAuthInstance().isSignedIn.get())
  });
}
