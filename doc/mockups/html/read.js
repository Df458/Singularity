var prep_done = false;
setTimeout(prepare, 2000);

function tryRead(element) {
    var rect = element.getBoundingClientRect();
    var in_view = rect.top <= window.innerHeight / 2 || rect.bottom <= window.innerHeight;
    if(in_view && element.dataset.read_set != 'true' && element.dataset.read != 'true') {
        webkit.messageHandlers.test.postMessage("v:" + element.dataset.id);
        element.dataset.read = 'true';
        element.classList.remove('unread');
    }
}

function toggleStar(button) {
    webkit.messageHandlers.test.postMessage("s:" + id);
    button.classList.toggle('active');
    button.parentNode.parentNode.parentNode.parentNode.dataset.starred = (button.parentNode.parentNode.parentNode.parentNode.dataset.starred == 'false' ? 'true' : 'false');
}

function toggleRead(button) {
    webkit.messageHandlers.test.postMessage("r:" + id);
    var parent = button.parentNode.parentNode.parentNode.parentNode;
    button.classList.toggle('active');
    if(parent.dataset.read_set == 'true' || parent.dataset.read == 'true') {
        parent.dataset.read = (parent.dataset.read == 'false' ? 'true' : 'false');
        parent.classList.toggle('unread');
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
    for(var i of items){
        var readbutton = i.children[0].children[0].children[1].children[0];
        var starbutton = i.children[0].children[0].children[1].children[1];
        if(i.dataset.read == 'true') {
            readbutton.classList.add('active');
        } else {
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

function toggleVisible(el) {
    
}
