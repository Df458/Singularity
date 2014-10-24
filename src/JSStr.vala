const string js_str = "<script>function isElementInViewport (el) {
    var rect = el.getBoundingClientRect();

    return (
    rect.top <= window.innerHeight / 2 ||
    rect.bottom <= window.innerHeight
    );
}

function callback (el, id) {
    window.location.assign('command://test/' + id);
    //el.style.color='red'
}


function fireIfElementVisible (el, id, callback) {
    return function () {
        if ( isElementInViewport(el) && el.getAttribute('marked') != 'true' && el.getAttribute('viewed') != 'true') {
            callback(el, id);
            el.setAttribute('viewed', 'true');
            el.setAttribute('marked', 'true');
        }
    }
}

function swapViewed() {
    if ( el.getAttribute('viewed') == 'false') {
        el.setAttribute('viewed', 'true');
    } else {
        el.setAttribute('viewed', 'false');
    }
    el.setAttribute('marked', 'true');
}

var items = document.getElementsByClassName('item-head');
items[0].setAttribute('marked', 'false');
callback(items[0], 0);
for(i = 1; i < items.length; ++i){
var handler = fireIfElementVisible (items[i], i, callback);
items[i].setAttribute('marked', 'false');
//addEventListener('DOMContentLoaded', handler, false);
addEventListener('load', handler, false);
addEventListener('scroll', handler, false);
addEventListener('resize', handler, false);
}</script>";
