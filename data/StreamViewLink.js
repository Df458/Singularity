var prep_done = false;
var wants_more = false;
var items;
setTimeout(prepare, 2000);

function readAll() {
    items = document.getElementsByTagName('article');

    for(var j = 0; j < items.length; ++j){
        var i = items[j];
        i.dataset.read = 'true';
        i.classList.remove('unread');
    }
}

function tryRead(element) {
    var rect = element.getBoundingClientRect();
    var in_view = rect.top <= window.innerHeight / 2 || rect.bottom <= window.innerHeight;
    if(in_view && element.dataset.read_set == 'false' && element.dataset.read != 'true') {
        // console.log(element.dataset);
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

function checkScroll() {
    for(var j = 0; j < items.length; ++j) {
        tryRead(items[j]);
    }

    if(window.pageYOffset + window.innerHeight > document.documentElement.clientHeight - 300 && wants_more) {
        webkit.messageHandlers.test.postMessage("p:");
        wants_more = false;
    }
}

function prepareItems(starting_id) {
    items = document.getElementsByTagName('article');

    for(var j = starting_id; j < items.length; ++j){
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
    }

    wants_more = true;
}

function prepare() {
    if(prep_done)
        return;
    prep_done = true;

    prepareItems(0);
}

window.addEventListener('scroll', checkScroll);
window.addEventListener('resize', checkScroll);
