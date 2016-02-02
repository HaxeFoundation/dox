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
		$(toggle).find("i").first().removeClass("fa-arrow-circle-o-right").addClass("fa-arrow-circle-o-down");
	} else {
		$(toggle).find("i").first().addClass("fa-arrow-circle-o-right").removeClass("fa-arrow-circle-o-down");
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
	$("#searchForm").removeAttr("action");
	query = query.replace(/[&<>"']/g, "");
	query = query.split(" ").join(".");
	if (!query || query.length<2) {
		$("#nav").removeClass("searching");
		$("#nav li").each(function(index, element){
			var e = $(element);
			e.css("display", "");
		});
		$("#nav ul:first-child").css("display", "block");
		$("#search-results-list").css("display", "none");
		return;
	}

	var listItems = [];
	var bestMatch = 200;
	$("#nav").addClass("searching");
	$("#nav ul:first-child").css("display","none");
	$("#nav li").each(function(index, element) {
		var e = $(element);
		if (!e.hasClass("expando")) {
			var content = e.attr("data_path");
			var match = searchMatch(content, query);
			if (match != -1 && match < bestMatch) {
				var url = dox.rootPath + e.attr("data_path").split(".").join("/") + ".html";
				$("#searchForm").attr("action", url);
				 // best match will be form action
				bestMatch = match;
			}
			
			if (match != -1) {
				var queryParts = query.split(".");
				var elLink = $("a", element);
				// highlight matched parts
				var elLinkContent = elLink.text().replace(new RegExp("(" + query.split(".").join("|") + ")", "ig"), "<strong>$1</strong>");
				var liStyle = (match == 0) ? ("font-weight:bold") : "";
				listItems.push("<li style='" + liStyle + "'><a href='"+elLink.attr("href")+"'>" + elLinkContent + "</a></li>");
			}
		}
	});
	if ($("#search-results-list").length == 0) {
		// append to nav
		$("#nav").parent().append("<ul id='search-results-list' class='nav nav-list'></ul>");
	}
	listItems.sort(); // put in order
	$("#search-results-list").css("display","block").html(listItems.join(""));
}

function searchMatch(text, query) {
	text = text.toLowerCase();
	query = query.toLowerCase();
	if (text == query) {
		return 0; // exact match
	} 
	var textParts = text.split(".");
	var queryParts = query.split(".");
	if (queryParts.length > textParts.length) {
		return -1;
	}
	if (queryParts.length == 1) { // no parts
		var lengthDiff = Math.abs(Math.max(text.length, query.length)-Math.min(text.length, query.length));
		var lastIndex = text.lastIndexOf(query);
		if (text.indexOf(query) == 0) return 1;
		else if (lastIndex > -1 && lastIndex == text.length-query.length) return lengthDiff * 2;
		return text.indexOf(query) > -1 ? lengthDiff * 3 : -1;
	}
	var matchPoints = 200;	
	for (var i = 0; i < queryParts.length; i++) {
		var queryPart = queryParts[i];
		if (queryPart == "") continue;
		for (var j = 0; j < textParts.length; j++) {
			var isLast = j == textParts.length-1;
			var textPart = textParts[j];
			var reward = isLast ? 3 : 1;
			if (textPart == queryPart) { 
				matchPoints -= reward * reward * reward; // exact part match
				if (i == j) {
					matchPoints -= reward; // same path
				}
			} 
			if (textPart.indexOf(queryPart) > -1) {
				matchPoints -= reward * reward; // has part
			} else {
				matchPoints += reward / 2; 
			}
		}
	}
	return (matchPoints <= 200) ? (matchPoints | 0) : -1;
}
