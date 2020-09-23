import './index/normalize.css';
import './index/retro.css';
import './index/baseline.css';
import './index/draggabilly.css';
import './Tile/Article.css';
import './Gui.css';
import './Mosaic.css';
import './Main.css';
import interact from '../js/interact/interact.min'
import Draggabilly from '../js/draggabilly/draggabilly.pkgd'
import Squire from '../js/squire/squire'
import {
    Elm
} from './Main.elm';
import * as serviceWorker from './serviceWorker';

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();

const app = Elm.Main.init({
    node: document.getElementById('root')
});



/* INTEROP

. Message and Type Diagram                      DOM ┆ vDOM                ┆
.                                                   ▲                     ┆
. ┃ Type ┣━━━⮞ Keep in sync.                        A custom Attribute      
.          ──⮞ Affect.                              E custom Event        ▲
. :::: Shadow (of same name).                       ▼                port P
. [  ] event, resp. Message (of same name).                               ▼
.                                                   ┆                       
.                                                   ┆                     ┆
.                                                                         ┆
.                                ╔═══════╗          ▲   ┏━━━━━━━━┓        ┆
.	             ╭────[ format ]─║ ::::: ⮜━━━━━━━━━━A━━━┫ Format ┃ ◀ user input
.                │               ╚═══════╝          ▼   ┗━━━━━━━━┛        ┆
.                │                                           ▲ modify     ┆
.                │                                  ┆        │            ┆
.                │                                  ┆        │            ┆     
.   apply format ▼                                           │            ┆
.           ┏━━━━━━━━━┓                             ▲   ╔═════════╗       ┆
.(cursor) ▶ ┃  caret  ┣━━━━━━━━━━[ caret ]━━━━━━━━━━E━━━⮞  :::::  ║       ┆
.           ┃         ┃                             ▲   ║         ║       ┆
(pointer) ▶ ┃ pointer ┣━━━━━━━━━[ pointer ]━━━━━━━━━E━━━⮞ ::::::: ║       ┆
.           ┃         ┃                             ▼   ║         ║       ┆ 
.  (text) ▶ ┃  draft  ┣━━━━━━━━━━[ draft ]━━━━━━━━━━E━━━⮞  :::::  ║ ▶ e.g. store draft...
.           ┗━━━━━━━━━┛                             ▼   ╚═════════╝       ┆ 
.      overwrite ▲                                           │            ┆     
.                │                                  ┆        +[ WalkAway ]┆
.                │                                  ┆        │            ┆
.                │                                           ▼ manifest         
.                │                ╔═══════╗         ▲   ┏━━━━━━━━━┓       ▲   ╔═════════╗
.                ╰────[ release ]─║ ::::: ⮜━━━━━━━━━A━━━┫ Release ┣━━━━━━━P━━━⮞ ::::::: ║
.                                 ╚═══════╝         ▼   ┗━━━━━━━━━┛       ▼   ╚═════════╝
.                                                            ▲ merge               │
.                                                   ┆        │            ┆        +(eventual synchronization)
.                                                   ┆        +[ Received ]┆        │
.                                                   ┆        │                     ▼
.                                                   ┆  ╔═══════════╗      ▲  ┏━━━━━━━━━━━┓
.                                                   ┆  ║ ::::::::: ⮜━━━━━━P━━┫ Canonical ┃ ◀ (peers)
.                                                   ┆  ╚═══════════╝      ▼  ┗━━━━━━━━━━━┛
.                                                   ┆                       
. -JS- --Squire Instance-- --Custom Element Node--  ╿  ---Elm Article---  ╿  ---Server---
.                                                   ┆                     ┆     


   

*/




// PORTS

/*
app.ports.toServer.subscribe(message=> {
	console.log ("Trying to send data to some server. Data is:", message);
})
*/














// ARTICLE EDITOR

Squire.prototype.replaceBlockWith = function(tag) {
    this.modifyBlocks(frag => {
        var output = this._doc.createDocumentFragment();
        var block = frag;
        while (block = Squire.getNextBlock(block)) {
            output.appendChild(
                this.createElement(tag, [Squire.empty(block)])
            );
        }
        return output;
    });
}



// CUSTOM ELEMENT

/* This technique hides the state of the editor (Squire) from Elm's vDOM differ.

- JS-to-Elm: js event -> Message -> Elm update
- Elm-to-JS: Elm view -> Attribute -> js attribute
- Everything below this layer, i.e. DOM children of the custom element,
  are in the js domain only. This enables imperative user interaction.
* reference: https://guide.elm-lang.org/interop/custom_elements.html

*/

var custom_editor = customElements.define('custom-editor',
    class extends HTMLElement {
        // required by Custom Elements 
        constructor() {
            super();
            console.log("create custom editor:")
            this.editor = this;

            this.field = document.createElement("article");
            this.field.tabIndex = 0;



            // ARTICLE SPECIFIC EVENTS

            this.squire = new Squire(this.field, {
                blockTag: 'P'
            });
            this.replacement = document.createElement("article");
            this.draft = (this.getAttribute("release") || "ERROR: no release html received");

            // E caret

            this.squire.addEventListener("pathChange", e => {
                const testThese = ["b", "strong", "i", "emph", "H1", "H2", "H3", "H4", "p", "div", "UL", "OL", "A", "LI"]
                let caret = new CustomEvent("caret", {
                    detail: {
                        caret: testThese.filter(f => this.squire.hasFormat(f))
                    }
                });
                this.editor.dispatchEvent(caret);
            })

            // E draft

            this.squire.addEventListener("input", e => {
                let draft = new CustomEvent("draft", {
                    detail: {
                        draft: this.draft,
                        id: this.id
                    }
                });
                this.editor.dispatchEvent(draft);
            })




        }

        static get observedAttributes() {
            return ['release', 'caret', 'id', 'state', 'format'];
        }

        connectedCallback() {
            // The element has been attached to the DOM.
            console.log(this.getAttribute("release"), "connected", );
            this.reflectState();

        }
        disconnectedCallback() {
            console.log(this.getAttribute("release"), "disconnected", );
            this.innerHTML = "";
        }
        attributeChangedCallback(attr, oldVal, newVal) {
            //console.log(attr, ":   ", oldVal, "----->", newVal);

            let doCommand = (command) => {
                console.log("DO", command)
                switch (command) {
                    case "increaseLevel":
                        if (this.squire.hasFormat('LI'))
                            this.squire.increaseListLevel();
                        else this.squire.increaseQuoteLevel();
                        break;
                    case "decreaseLevel":
                        if (this.squire.hasFormat('LI'))
                            this.squire.decreaseListLevel();
                        else this.squire.decreaseQuoteLevel();
                        break;
                    case "makeUnorderedList":
                        this.squire.makeUnorderedList();
                        break;
                    case "makeOrderedList":
                        this.squire.makeOrderedList();
                        break;
                    case "removeList":
                        this.squire.removeList();
                        break;
                    case "makeTitle":
                        this.squire.replaceBlockWith('h1');
                        break;
                    case "makeHeader":
                        this.squire.replaceBlockWith('h2');
                        break;
                    case "makeSubheader":
                        this.squire.replaceBlockWith('h3');
                        break;
                    case "removeHeader":
                        this.squire.replaceBlockWith('p');
                        break;
                    case "bold":
                        this.squire.bold();
                        break;
                    case "removeBold":
                        this.squire.removeBold();
                        break;
                    case "italic":
                        this.squire.italic();
                        break;
                    case "removeItalic":
                        this.squire.removeItalic();
                        break;
                    case "undo":
                        this.squire.undo();
                        break;
                    case "redo":
                        this.squire.redo();
                        break;
                    case "removeAllFormatting":
                        this.squire.removeAllFormatting();
                        break;
                }
                this.squire.focus();
            };


            switch (attr) {
                case 'state':
                    this.reflectState();
                    break;
                case 'release':
                    if (this.squire) this.squire.setHTML(newVal);
                    console.log(oldVal, "-> set release:", newVal)
                    break;
                case 'format':
                    if (newVal != "") doCommand(newVal);
            }
        }
        reflectState() {
            var handle;
            if (this.hasAttribute('state') && this.getAttribute('state') == 'editing') {
                if (this.contains(this.replacement)) this.removeChild(this.replacement);
                if (!this.contains(this.field)) this.appendChild(this.field);
                handle = this.field;
            } else {
                if (this.contains(this.field))
                    this.removeChild(this.field);
                if (this.replacement && !this.contains(this.replacement)) {
                    if (this.hasAttribute("release"))
                        this.replacement.innerHTML = this.getAttribute("release");
                    this.appendChild(this.replacement);
                }
                handle = this.replacement;

                // POINTER EVENTS AND DRAGGING

                let draggie = new Draggabilly(handle);
                console.log("adding a draggie:", draggie)
                draggie.on('dragMove', function() {
                    console.log('dragMove', this.position.x, this.position.y);
                });


                // E delta

                // E size

                // E press

                // E tap

                // E grab

                // E drop
            }
        }
        get draft() {
            return this.squire.getHTML();
        }
        set draft(val) {
            this.squire.setHTML(val);
        }
    }
)