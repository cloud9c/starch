module ApplicationHelper
	def render_document_html(html)

		doc = Nokogiri::HTML(html)

		doc.css('a').each do |link|
		  link['target'] = '_blank'
		end

		html = doc.to_html

		return sanitize(html, 
			tags: %w[
				h1 h2 h3 h4 h5 h6 h7 h8 br b i strong em a pre code img tt div ins del sup sub
				p ol ul table thead tbody tfoot blockquote dl dt dd kbd q samp var hr ruby rt
				rp li tr td th s strike summary details figure figcaption audio video source
				small iframe
			],
			attributes: %w[
				href src longdesc itemscope itemtype cite 
				poster playsinline loop muted controls preload 
				align width height 
				abbr accept accept-charset accesskey action alt axis 
				border cellpadding cellspacing char charoff charset 
				checked clear cols colspan color compact coords 
				datetime dir disabled enctype for frame headers 
				hreflang hspace ismap label lang maxlength 
				media method multiple name nohref noshade nowrap 
				open prompt readonly rel rev rows rowspan rules 
				scope selected shape size span start summary 
				tabindex target title type usemap valign value 
				vspace itemprop id
			])
	end
end
