function createCookie(name, value, days) {
	localStorage.setItem(name, value);
}

function readCookie(name) {
	return localStorage.getItem(name);
}

function toggleInherited(el) {
	var toggle = $(el).closest(".toggle");
	toggle.toggleClass("toggle-on");
	if (toggle.hasClass("toggle-on")) {
		$("i", toggle).removeClass("fa-arrow-circle-o-right").addClass("fa-arrow-circle-o-down");
	} else {
		$("i", toggle).addClass("fa-arrow-circle-o-right").removeClass("fa-arrow-circle-o-down");
	}
    return false;
}

function toggleCollapsed(el) {
	var toggle = $(el).closest(".expando");
	toggle.toggleClass("expanded");

	if (toggle.hasClass("expanded")) {
		$("i", toggle).removeClass("fa-arrow-circle-o-right").addClass("fa-arrow-circle-o-down");
	} else {
		$("i", toggle).addClass("fa-arrow-circle-o-right").removeClass("fa-arrow-circle-o-down");
	}
	updateTreeState();
    return false;
}

function updateTreeState(){
	var states = [];
	$("#nav .expando").each(function(i, e){
		states.push($(e).hasClass("expanded") ? 1 : 0);
	});
	var treeState = JSON.stringify(states);
	createCookie("treeState", treeState);
}

var filters = {};

function selectVersion(e) {
	setVersion($(e.target).parent().attr("data"));
}

function setPlatform(platform) {
	createCookie("platform", platform);
	$("#select-platform").val(platform);

	var styles = ".platform { display:none }";
	var platforms = dox.platforms;
	if (platform == "flash" || platform == "js") {
		styles += ".package-sys { display:none; } ";
	}
	for (var i = 0; i < platforms.length; i++) {
		var p = platforms[i];
		if (platform == "sys") {
			if (p != "flash" && p != "js")	{
				styles += ".platform-" + p + " { display:inherit } ";
			}
		}
		else
		{
			if (platform == "all" || p == platform)	{
				styles += ".platform-" + p + " { display:inherit } ";
			}
		}
	}

	if (platform != "flash" && platform != "js") {
		styles += ".platform-sys { display:inherit } ";
	}

	$("#dynamicStylesheet").text(styles);
}
/*
function setVersion(version) {
	createCookie("version", version);
}
*/

$(document).ready(function(){
	$("#nav").html(navContent);
	var treeState = readCookie("treeState");

	$("#nav .expando").each(function(i, e){
		$("i", e).first().addClass("fa-arrow-circle-o-right").removeClass("fa-arrow-circle-o-down");
	});

	$(".treeLink").each(function() {
		this.href = this.href.replace("::rootPath::", dox.rootPath);
	});

	if (treeState != null)
	{
		var states = JSON.parse(treeState);
		$("#nav .expando").each(function(i, e){
			if (states[i]) {
				$(e).addClass("expanded");
				$("i", e).first().removeClass("fa-arrow-circle-o-right").addClass("fa-arrow-circle-o-down");
			}
		});
	}
	$("head").append("<style id='dynamicStylesheet'></style>");

	setPlatform(readCookie("platform") == null ? "all" : readCookie("platform"));
	//setVersion(readCookie("version") == null ? "3_0" : readCookie("version"));

	$("#search").on("input", function(e){
		searchQuery(e.target.value);
	});

	$("#select-platform").selectpicker().on("change", function(e){
		var value = $(":selected", this).val();
		setPlatform(value);
	});

	$("#nav a").each(function () {
		if (this.href == location.href) {
			$(this.parentElement).addClass("active");
		}
	});

    // Because there is no CSS parent selector
    $("code.prettyprint").parents("pre").addClass("example");
});

function searchQuery(query) {
	query = query.toLowerCase();
	$("#searchForm").removeAttr("action");
	if (query == "") {
		$("#nav").removeClass("searching");
		$("#nav li").each(function(index, element){
			var e = $(element);
			e.css("display", "");
		});
		return;
	}

	console.log("Searching: "+query);

	var searchSet = false;

	$("#nav").addClass("searching");
	$("#nav li").each(function(index, element){
		var e = $(element);
		if (!e.hasClass("expando")) {
			var content = e.attr("data_path").toLowerCase();
			var match = searchMatch(content, query);
			if (match && !searchSet) {
				var url = dox.rootPath + e.attr("data_path").split(".").join("/") + ".html";
				$("#searchForm").attr("action", url);
				searchSet = true;
			}
			e.css("display", match ? "" : "none");
		}
	});

}

function searchMatch(text, query) {
	var textParts = text.split(".");
	var queryParts = query.split(".");
	if (queryParts.length > textParts.length) {
		return false;
	}
	if (queryParts.length == 1) {
		return text.indexOf(query) > -1;
	}
	for (i = 0; i < queryParts.length; ++i) {
		if (textParts[i].indexOf(queryParts[i]) != 0) { // starts with
			return false;
		}
	}
	return true;
}
