function toggleInherited(el) {
	var toggle = $(el).closest(".toggle");
	toggle.toggleClass("toggle-on");
	if (toggle.hasClass("toggle-on")) {
		$("img", toggle).attr("src", "/dox/triangle-opened.png");
	} else {
		$("img", toggle).attr("src", "/dox/triangle-closed.png");
	}
}

function toggleCollapsed(el) {
	var toggle = $(el).closest(".expando");
	console.log(toggle);
	toggle.toggleClass("expanded");

	if (toggle.hasClass("expanded")) {
		$("img", toggle).first().attr("src", "/dox/triangle-opened.png");
	} else {
		$("img", toggle).first().attr("src", "/dox/triangle-closed.png");
	}
}