const string css_str ="""
body {
    background-color: #bbb;
    margin: 0;

    font-family: sans;
}

a {
    text-decoration: none;
}

header.column {
    padding: 12px;
}

.title.column {
    margin-left: 31px;
    margin-top: 0;
}

.footer-heading.column {
    margin-top: 0;
}

.title a {
    color: #222;
}

.title a:hover {
    color: #666;
}

.content.column {
    padding: 12px;
    margin-bottom: 152px;
}

footer.column {
    position: fixed;
    bottom: 0;
    left: 0;
    right: 0;
    height: 128px;
    padding: 12px;
    background: #666;

	box-shadow: 0px 0px 10px 5px #2B2B2B;
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

.star {
    align-self: flex-start;
    -webkit-align-self: flex-start;
    margin-right: -25px;
    float: left;
    -webkit-clip-path: inset(0 50% 0 0);
    clip-path: inset(0 50% 0 0);
}
.star#active {
    -webkit-clip-path: inset(0 0 0 50%);
    clip-path: inset(0 0 0 50%);
    margin-right: 0;
    margin-left: -25px;
}
/*---------------------------------------------------------------------------*/

article.stream {
    padding: 12px;
    margin: 18px;
    background: #aaaaaa;
    border-radius: 3px;
    border-top: 2px solid #777;
    box-shadow: 0 0 3px #555;
}

article.stream#unread {
    border-top: 2px solid #36c;
}

article.stream+article.stream {
    /* border-top: 3px solid #777; */
}

.stream#top {
    display: flex;
    justify-content: space-between;
    align-content: space-between;
    flex-flow: row wrap;
    -webkit-display: flex;
    -webkit-justify-content: space-between;
    -webkit-align-content: space-between;
    -webkit-flex-flow: row nowrap;
}

.stream#posted {
    flex: 2
}

.title.stream {
    margin-top: 0;
    margin-bottom: 6px;
}

.content.stream {
    padding-top: 12px;
    padding-bottom: 12px;
}

.stream#taglist {
    color: #777777;
}

/*---------------------------------------------------------------------------*/

body.grid {
    display: flex;
    flex-wrap: wrap;
    align-content: flex-start;
}

article.grid {
    width: 180px;
    height: 180px;
    padding: 12px;
    margin: 9px;
    border: 1px solid;
    border-radius: 6px;
}

.grid.star {
    position: absolute;
}

.grid#preview {
    height: 150px;
    overflow: hidden;
}

.grid.title {
    margin: 0;
}

.grid#taglist {
    position: absolute;
    font-size: 0.75em;
    overflow: hidden;
    opacity: 0.5;
}

article.grid-full {
    position: fixed;
}
""";

const string js_str = """<script>function isElementInViewport (el) {
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
</script>""";

const string star_icon_base64 = "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";

//const string star_icon_base64 = "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";
