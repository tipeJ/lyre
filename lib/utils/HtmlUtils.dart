String parseShittyFlutterHtml(String html){
  return html.replaceAll("&lt;", "<").replaceAll("&gt;", ">");
}