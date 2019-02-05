# https://godotdevelopers.org/forum/discussion/18999/issues-with-xmlparser

var mainList = []
var xp = XMLParser.new()
var regex = RegEx.new()
var err

func _init():
	regex.compile("(<[^<]+>)")

func parse_buffer(buffer):
	xp.open_buffer(buffer)
	
	var art
	var subdict
	
	while xp.read() == 0:
		art = xp.get_node_type()

		if art == XMLParser.NODE_ELEMENT:
			subdict = {}
			subdict["name"] = xp.get_node_name()
			subdict["cdata"] = ""
			subdict["childs"] = []
			mainList.append(subdict)
			accu(subdict)


func accu(dict):
	var art
	var subdict
	while xp.read() == 0:
		art = xp.get_node_type()
		if art == XMLParser.NODE_ELEMENT:
			subdict = {}
			subdict["name"] = xp.get_node_name()
			subdict["cdata"] = ""
			subdict["childs"] = []
			dict["childs"].append(subdict)
			if !xp.is_empty():
				accu(subdict)
		elif art == XMLParser.NODE_ELEMENT_END:
			return
		elif art == XMLParser.NODE_TEXT:
			var untrimmed = xp.get_node_data().xml_unescape()
			var trimmed = untrimmed.strip_edges()
			if ! trimmed.empty():
				dict["cdata"] = dict["cdata"] + untrimmed
		elif art == XMLParser.NODE_CDATA:
			var untrimmed = xp.get_node_name().xml_unescape()
			var trimmed = untrimmed.strip_edges()
			var cleaned = remove_style_tags(trimmed)
			if ! cleaned.empty():
				dict["cdata"] = dict["cdata"] + cleaned

func remove_style_tags(original: String) -> String:
	var matches = regex.search_all(original)
	
	if matches == null:
		return original
	
	var clean := original
	for m in matches:
		var tag = (m as RegExMatch).get_string(1)
		clean = clean.replace(tag, "")
	return clean
