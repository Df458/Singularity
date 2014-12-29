const string js_str = "<script>function isElementInViewport (el) {
    var rect = el.getBoundingClientRect();

    return (
    rect.top <= window.innerHeight / 2 ||
    rect.bottom <= window.innerHeight
    );
}

function callback (el, id) {
    window.location.assign('command://read/' + id);
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

function toggleStar() {
    window.location.assign('command://toggleStarred/' + this.id);
    if(this.className == 'starButton') {
        this.className = 'starButtonD';
    } else {
        this.className = 'starButton';
    }
}

function toggleRead(el, id) {
    window.location.assign('command://toggleRead/' + id);
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
}

var star_buttons = document.getElementsByClassName('starButton');
for(i = 0; i < star_buttons.length; ++i) {
    star_buttons[i].id = i;
    star_buttons[i].addEventListener('click', toggleStar, false);
}
var star_buttonsd = document.getElementsByClassName('starButtonD');
for(i = 0; i < star_buttonsd.length; ++i) {
    star_buttonsd[i].id = i;
    star_buttonsd[i].addEventListener('click', toggleStar, false);
}
</script>";

const string star_icon_base64 = "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";
