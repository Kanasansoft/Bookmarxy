(
	function(){
		var elem=document.createElement("div");
		var text=document.createTextNode("Bookmarxy is starting!");
		elem.appendChild(text);
		elem.style.padding="10px";
		elem.style.fontSize="24px";
		elem.style.textAlign="center";
		elem.style.color="#ff9999";
		elem.style.backgroundColor="#000000";
		document.body.insertBefore(
			elem,
			document.body.firstChild
		);
	}
)();
