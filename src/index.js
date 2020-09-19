import './normalize.css';
import './retro.css';
import './layout.css';
import './formats.css';
import './ui.css';
import './mosaic.css';
import './main.css';
import Squire from '../squire/squire'
import { Elm } from './Main.elm';
import * as serviceWorker from './serviceWorker';

// If you want your app to work offline and load faster, you can change
// unregister() to register() below. Note this comes with some pitfalls.
// Learn more about service workers: https://bit.ly/CRA-PWA
serviceWorker.unregister();


const app = Elm.Main.init({
	node: document.getElementById('root')
  });

  

/* INTEROP

. Interop Diagram                                   ┆                      ┆
.                                                   ┆ vDom:                ┆
. ━━━▶ Synchronize.                                 A Custom Attribute     ┆
. ──▶  Affect.                                      E Custom Event         ┆
. :::: Shadow (of same name).                       ┆                 Port P
. [  ] event, resp. Message (of same name).         ┆                      ┆
.                                                   ┆                      ┆
.                                                   ┆                      ┆
.                                                   ┆                      ┆
.                                ╔═══════╗          ┆ ╻┏━━━━━━━━┓          ┆
.	           ╭──────[ format ]─║ ::::: ◀━━━━━━━━━━A━┫┃ Format ┃ ◀ user input
.              │                 ╚═══════╝          ┆ ╹┗━━━━━━━━┛          ┆
.              │                                    ┆      ▲ modify        ┆
.              │                                    ┆      │               ┆
.              │                                    ┆      │               ┆     
. apply format ▼                                    ┆      │               ┆
.           ┏━━━━━━━┓╻                              ┆  ╔═══════╗           ┆
user caret ▶┃ caret ┃┣━━━━━━━━━[ caret ]━━━━━━━━━━━━E━━▶ ::::: ║           ┆
            ┃       ┃                               ┆  ║       ║           ┆
user draft ▶┃ draft ┃┣━━━━━━━━━[ draft ]━━━━━━━━━━━━E━━▶ ::::: ║ ▶ e.g. store draft...
.           ┗━━━━━━━┛╹                              ┆  ╚═══════╝           ┆ 
.    overwrite ▲                                    ┆      │               ┆     
.              │                                    ┆      │┄[ WalkAway ]  ┆
.              │                                    ┆      │               ┆
.              │                                    ┆      ▼ manifest      ┆     
.              │                  ╔═══════╗         ┆ ╻┏━━━━━━━━━┓╻        ┆  ╔═════════╗
.              ╰──────[ release ]─║ ::::: ◀━━━━━━━━━A━┫┃ Release ┃┣━━━━━━━━P━━▶ ::::::: ║
.                                 ╚═══════╝         ┆ ╹┗━━━━━━━━━┛╹        ┆  ╚═════════╝
.                                                   ┆      ▲ merge         ┆       │
.                                                   ┆      │               ┆       │┄(eventual synchronization)
.                                                   ┆      │┄[ Received ]  ┆       │
.                                                   ┆      │               ┆       ▼
.                                                   ┆  ╔═══════╗           ┆ ╻┏━━━━━━━━━━━┓
.                                                   ┆  ║ ::::: ◀━━━━━━━━━━━P━┫┃ Canonical ┃ ◀ peers
.                                                   ┆  ╚═══════╝           ┆ ╹┗━━━━━━━━━━━┛
.                                                   ┆                      ┆
.        Squire Instance     Custom Element Node    ╿      Elm Article     ╿  Server

   

*/




// PORTS

/*
app.ports.toServer.subscribe(message=> {
	console.log ("Trying to send data to some server. Data is:", message);
})
*/





// ARTICLE EDITOR

Squire.prototype.replaceBlockWith = function ( tag ) {
	this.modifyBlocks( frag => {
		var output = this._doc.createDocumentFragment();
		var block = frag;
		while ( block = Squire.getNextBlock( block ) ) {
		output.appendChild (
			this.createElement( tag, [ Squire.empty( block ) ] )
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
			this.editor = this;
			this.field = null;
			this.squire = null;
			this.replacement = null;

			this.field = document.createElement("article");
			this.field.tabIndex = 0;
			this.squire = new Squire( this.field, {
				blockTag: 'P'
			} );
			this.replacement = document.createElement("article");

			this.squire.addEventListener("pathChange", e=> {
				const testThese =
					["b", "strong", "i", "emph", "H1", "H2", "H3", "H4", "p", "div", "UL", "OL", "A", "LI"]
				var caret = new CustomEvent ("caret", {detail: 
					{caret: testThese.filter (f=>this.squire.hasFormat(f))}
				});
				this.editor.dispatchEvent(caret);
			})

			this.squire.addEventListener("input", e=> {
				// do not change attributes because that would wake up the virtual-dom differ!
				const draft = new CustomEvent ("draft", {detail: 
					{draft: this.draft, id: this.id}
				});
				this.editor.dispatchEvent(draft);
			})


			this.draft = ( this.getAttribute("release") || "ERROR: no release html received" );
			
		}
		
		static get observedAttributes() { return ['release', 'caret', 'id', 'state', 'format']; }

		doCommand (command) {
			console.log("DO",command)
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
				case "makeUnorderedList":this.squire.makeUnorderedList(); break;
				case "makeOrderedList":this.squire.makeOrderedList(); break;
				case "removeList":this.squire.removeList(); break;
				case "makeTitle":this.squire.replaceBlockWith('h1'); break;
				case "makeHeader":this.squire.replaceBlockWith('h2'); break;
				case "makeSubheader":this.squire.replaceBlockWith('h3'); break;
				case "removeHeader":this.squire.replaceBlockWith('p'); break;
				case "bold":this.squire.bold(); break;
				case "removeBold":this.squire.removeBold(); break;
				case "italic":this.squire.italic(); break;
				case "removeItalic":this.squire.removeItalic(); break;
				case "undo":this.squire.undo(); break;
				case "redo":this.squire.redo(); break;
				case "removeAllFormatting":this.squire.removeAllFormatting(); break;
			}
			this.squire.focus();
		}
		connectedCallback() {
			// The element has been attached to the DOM.
			console.log ("JS-- ConnectedCallback --.");
			this.reflectState();
			
		}
		disconnectedCallback() {
			console.log ("JS-- DisonnectedCallback --.");
			this.innerHTML = "";
		}
		attributeChangedCallback(attr, oldVal, newVal){
			console.log(attr,":   ",oldVal,"----->",newVal);
			switch (attr) {
				       case 'state': this.reflectState();
				break; case 'caret': this.doCommand(newVal);
				break; case 'release': if(this.squire) this.squire.setHTML(newVal);
				break; case 'id': this.id_indicator.innerText = newVal;
				break; case 'format' : this.doCommand(newVal);
			}
		}

		reflectState(){
			if (this.hasAttribute('state') && this.getAttribute('state') == 'editing'){
				if (this.contains (this.replacement)) this.removeChild (this.replacement);
				if (!this.contains (this.field)) this.appendChild (this.field);
			}
			else {
				if (this.contains (this.field))
					this.removeChild (this.field);
				if (this.replacement && !this.contains (this.replacement)) {
					if (this.hasAttribute("release"))
						this.replacement.innerHTML = this.getAttribute("release");
					this.appendChild(this.replacement);
				}
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





