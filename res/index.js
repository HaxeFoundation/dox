var base = "/dox/pages/";

function createCookie(name, value, days) {
    if (days) {
        var date = new Date();
        date.setTime(date.getTime() + (days * 24 * 60 * 60 * 1000));
        var expires = "; expires=" + date.toGMTString();
    } else var expires = "";
    document.cookie = escape(name) + "=" + escape(value) + expires + "; path=/";
}

function readCookie(name) {
    var nameEQ = escape(name) + "=";
    var ca = document.cookie.split(';');
    for (var i = 0; i < ca.length; i++) {
        var c = ca[i];
        while (c.charAt(0) == ' ') c = c.substring(1, c.length);
        if (c.indexOf(nameEQ) == 0) return unescape(c.substring(nameEQ.length, c.length));
    }
    return null;
}

function toggleInherited(el) {
	var toggle = $(el).closest(".toggle");
	toggle.toggleClass("toggle-on");
	if (toggle.hasClass("toggle-on")) {
		$("img", toggle).attr("src", baseUrl + "/triangle-opened.png");
	} else {
		$("img", toggle).attr("src", baseUrl + "/triangle-closed.png");
	}
}

function toggleCollapsed(el) {
	var toggle = $(el).closest(".expando");
	// console.log(toggle);
	toggle.toggleClass("expanded");

	if (toggle.hasClass("expanded")) {
		$("img", toggle).first().attr("src", baseUrl + "/triangle-opened.png");
	} else {
		$("img", toggle).first().attr("src", baseUrl + "/triangle-closed.png");
	}
	updateTreeState();
}

function updateTreeState(){
	var states = [];
	$(".packages .expando").each(function(i, e){
		states.push($(e).hasClass("expanded") ? 1 : 0);
	});
	var treeState = JSON.stringify(states);
	createCookie("treeState", treeState);
}

$(document).ready(function(){
	$("#nav").html(navContent);
	var treeState = readCookie("treeState");
	if (treeState != null)
	{
		var states = JSON.parse(treeState);
		$(".packages .expando").each(function(i, e){
			if (states[i]) {
				$(e).addClass("expanded");
				$("img", e).first().attr("src", baseUrl + "/triangle-opened.png");
			}
		});
	}
});