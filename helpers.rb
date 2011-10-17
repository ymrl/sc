#coding:UTF-8
helpers do
  def h s
    CGI.escapeHTML s
  end

  def auto_link s
    regURL = /(http:\/\/[^'"\s　]+)/
    s.split(regURL).map{|t|t.match(regURL)?"<a href=\"#{h t}\" target=\"_blank\">#{h t}</a>":h(t)}.join('')
  end

end
