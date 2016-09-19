const string css_str ="""
body {
    background-color: #bbb;
    margin: 0;

    font-family: sans;
}

a {
    text-decoration: none;
}

.title a {
    color: #222;
}

.title a:hover {
    color: #666;
}

footer h3 {
    margin-bottom: 0;
}

footer section {
    margin-bottom: 12px;
}

hr {
    border-style: none;
    border-top: 1px dashed;
    margin: 3px;
}

.star, .read-button {
    align-self: flex-start;
    -webkit-align-self: flex-start;
    margin-right: -25px;
    float: left;
    -webkit-clip-path: inset(0 50% 0 0);
    clip-path: inset(0 50% 0 0);

    opacity: 0;
    transition: opacity 0.15s;
}
article:hover .star, article:hover .read-button {
    opacity: 1;
    transition: opacity 0.15s;
}
.star.active, .read-button.active{
    -webkit-clip-path: inset(0 0 0 50%);
    clip-path: inset(0 0 0 50%);
    margin-right: 0;
    margin-left: -25px;
    opacity: 1;
}
""";

const string css_str_stream ="""
article {
    padding: 12px;
    margin: 18px;
    background: #aaaaaa;
    border-radius: 3px;
    border-top: 2px solid #777;
    box-shadow: 0 0 3px #555;
}

article.unread {
    border-top: 2px solid #36c;
}

article+article {
    /* border-top: 3px solid #777; */
}

.title {
    display: flex;
    justify-content: space-between;
    align-content: space-between;
    flex-flow: row wrap;
    -webkit-display: flex;
    -webkit-justify-content: space-between;
    -webkit-align-content: space-between;
    -webkit-flex-flow: row wrap;
}

.post-info {
    flex: 2
}

.title a {
    margin-top: 0;
    margin-bottom: 6px;
    font-size: x-large;
    font-weight: bold;
}

.content {
    padding-top: 12px;
    padding-bottom: 12px;
    overflow: hidden;
}

.tags-list {
    color: #777777;
}
""";

const string js_str = """
var prep_done = false;
setTimeout(prepare, 2000);

function tryRead(element) {
    var rect = element.getBoundingClientRect();
    var in_view = rect.top <= window.innerHeight / 2 || rect.bottom <= window.innerHeight;
    if(in_view && element.dataset.read_set == 'false' && element.dataset.read != 'true') {
        console.log(element.dataset);
        webkit.messageHandlers.test.postMessage("v:" + element.dataset.id);
        element.dataset.read = 'true';
        element.classList.remove('unread');
    }
}

function toggleStar(button) {
    var parent = button.parentNode.parentNode.parentNode.parentNode;
    button.classList.toggle('active');
    parent.dataset.starred = (parent.dataset.starred == 'false' ? 'true' : 'false');
    webkit.messageHandlers.test.postMessage("s:" + parent.dataset.id);
}

function toggleRead(button) {
    var parent = button.parentNode.parentNode.parentNode.parentNode;
    button.classList.toggle('active');
    if(parent.dataset.read_set == 'true' || parent.dataset.read == 'true') {
        parent.dataset.read = (parent.dataset.read == 'false' ? 'true' : 'false');
        parent.classList.toggle('unread');
        webkit.messageHandlers.test.postMessage("r:" + parent.dataset.id);
    }
    parent.dataset.read_set = 'true';
}

function generateReadCallback(el) {
    return function() { tryRead(el); }
}

function prepare() {
    if(prep_done)
        return;
    prep_done = true;
    var items = document.getElementsByTagName('article');
    for(var j = 0; j < items.length; ++j){
        var i = items[j];
        var readbutton = i.children[0].children[0].children[1].children[0];
        var starbutton = i.children[0].children[0].children[1].children[1];
        i.dataset.read_set = 'false';
        if(i.dataset.read == 'false') {
            i.classList.add('unread');
        }
        if(i.dataset.starred == "true") {
            starbutton.classList.add('active');
        }
        readbutton.onclick = function() {toggleRead(this);}
        starbutton.onclick = function() {toggleStar(this);}

        tryRead(i);
        addEventListener('scroll', generateReadCallback(i), false);
        addEventListener('resize', generateReadCallback(i), false);
    }
}
""";
