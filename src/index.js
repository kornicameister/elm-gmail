import './main.css';
import 'materialize-css/dist/css/materialize.css';

import { Main } from './Main.elm';

import registerServiceWorker from './registerServiceWorker';

Main.embed(document.getElementById('root'));

registerServiceWorker();
