extends Node

const FAKE_NEWS_URL = "https://www.thedailymash.co.uk/feed"
const REAL_NEWS_URL = "https://www.dailymail.co.uk/home/index.rss"
const FAKE_NEWS = "thedailymash"
const REAL_NEWS = "dailymail"

var fake_news = []
var real_news = []
var mixed_news = []
var article_idx = 0
var score = 0

var error_msg = ""

enum State { LOADING, PLAYING, GAME_OVER, ERROR }

func _ready():
	randomize()
	update_state(State.LOADING)
	$FakeNewsHTTPRequest.request(FAKE_NEWS_URL, PoolStringArray(), false)
	$RealNewsHTTPRequest.request(REAL_NEWS_URL, PoolStringArray(), false)

func _on_FakeNewsHTTPRequest_request_completed(result, response_code, headers, body):
	var articles = get_news_from_xml(body, true)
		
	fake_news = articles
		
	if !fake_news.empty() && !real_news.empty():
		update_state(State.PLAYING)

func _on_RealNewsHTTPRequest_request_completed(result, response_code, headers, body):
	var articles = get_news_from_xml(body, false)
		
	real_news = articles
		
	if !fake_news.empty() && !real_news.empty():
		update_state(State.PLAYING)

func get_news_from_xml(body, is_fake):
	
	if body.size() == 0:
		error_msg = "Got empty body"
		update_state(State.ERROR)
		return
	
	var parser = preload("res://Parser.gd").new()
	parser.parse_buffer(body)
	var news = []
	var rss = parser.mainList[0]
	var channel = rss["childs"][0]
	
	for item in channel["childs"]:
		if item["name"] != "item":
			continue
		
		var article = {}
		article.is_fake = is_fake
		news.append(article)
		
		for property in item["childs"]:
			if property["name"] == "title":
				article.title = property["cdata"]
			if property["name"] == "description":
				article.description = property["cdata"]
			if property["name"] == "link":
				article.source_url = property["cdata"]
	
	if news.empty():
		error_msg = "No news to review :("
		update_state(State.ERROR)
		
	return news

func update_state(state):
	if state == State.LOADING: 
		get_main_title().text = "Loading news..."
		get_start_new_game_button().visible = false
		get_news_container().visible = false
		get_voting_buttons_container().visible = false
	elif state == State.PLAYING:
		get_start_new_game_button().visible = false
		get_news_container().visible = true
		get_voting_buttons_container().visible = true
		
		mixed_news = []
		article_idx = 0
		score = 0
		
		var f_news = fake_news.duplicate()
		var r_news = real_news.duplicate()
		
		for i in range(10):
			var a = f_news if randi() % 2 == 0 else r_news
			var idx = randi() % a.size()
			mixed_news.append(a[idx])
			a.remove(idx)
		
		update_for_current_article()
	elif state == State.GAME_OVER:
		get_start_new_game_button().visible = true
		get_news_container().visible = false
		get_voting_buttons_container().visible = false
		get_main_title().text = "You gave %s / %s correct answers!" % [score, mixed_news.size()]
	elif state == State.ERROR:
		get_main_title().text = error_msg
		get_start_new_game_button().visible = false
		get_news_container().visible = false
		get_voting_buttons_container().visible = false

func get_main_title():
	return get_node("MarginContainer/VBoxContainer/TitleLabel")
	
func get_start_new_game_button():
	return get_node("MarginContainer/VBoxContainer/StartButton")
	
func get_news_container():
	return get_node("MarginContainer/VBoxContainer/CenterContainer")
	
func get_voting_buttons_container():
	return get_node("MarginContainer/VBoxContainer/VotingButtons")

func get_article_title():
	return get_node("MarginContainer/VBoxContainer/CenterContainer/HBoxContainer/VBoxContainer/TitleLabel")

func get_article_description():
	return get_node("MarginContainer/VBoxContainer/CenterContainer/HBoxContainer/VBoxContainer/DescriptionLabel")

func _on_RealNewsButton_pressed():
	var article = mixed_news[article_idx]
	if !article.is_fake:
		score += 1
	
	article_idx += 1
	update_for_current_article()

func _on_FakeNewsButton_pressed():
	var article = mixed_news[article_idx]
	if article.is_fake:
		score += 1
	
	article_idx += 1
	update_for_current_article()

func _on_StartButton_pressed():
	update_state(State.PLAYING)
	
func update_for_current_article():
	if article_idx >= mixed_news.size():
		update_state(State.GAME_OVER)
		return
		
	get_main_title().text = "Real or fake? [%s / %s]" % [(article_idx + 1), mixed_news.size()]
	var article = mixed_news[article_idx]
	get_article_title().text = article.title
	get_article_description().text = article.description
