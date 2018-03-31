import "bulma/css/bulma.css";

import { Main } from "./Main.elm";

import registerServiceWorker from "./registerServiceWorker";
import { load as loadGApi, signIn, signOut, getUser } from './google';

import "./main.css";

const app = Main.embed(document.getElementById('root'));
app.ports.gApiSignIn.subscribe(() => signIn());
app.ports.gApiSignOut.subscribe(() => signOut());

registerServiceWorker();

loadGApi(() => app.ports.gApiIsSignedIn.send(getUser()));
