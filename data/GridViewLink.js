var prep_done = false;
var large_elements;
var darkener;
var display_id;

function view_item(element) {
        // console.log(element.dataset);
    if(element.dataset.read != 'true') {
        // console.log(element.dataset);
        webkit.messageHandlers.test.postMessage("v:" + element.dataset.id);
        element.dataset.read = 'true';
        element.classList.remove('unread');
    }

    // TODO: Display next article
    display_id = parseInt(element.dataset.id);
    large_elements[display_id].classList.remove('full-hidden');
    darkener.classList.remove('full-hidden');
}

function hide() {
    large_elements[display_id].classList.add('full-hidden');
    darkener.classList.add('full-hidden');
}

function prepare() {
    if(prep_done)
        return;
    prep_done = true;

    large_elements = document.getElementsByClassName('full-article');
    darkener = document.getElementsByClassName('darkener')[0];
}
