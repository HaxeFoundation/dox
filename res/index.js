function toggleInherited(el) {
	var toggle = $(el).closest(".toggle");
	toggle.toggleClass("toggle-on");
	if (toggle.hasClass("toggle-on")) {
		$("img", toggle).attr("src", "http://10.0.2.89/mdk/doc/triangle-opened.png");
	} else {
		$("img", toggle).attr("src", "http://10.0.2.89/mdk/doc/triangle-closed.png");
	}
}