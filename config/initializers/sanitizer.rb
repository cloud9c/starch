Rails.application.configure do
  config.action_view.sanitized_allowed_tags = %w[
    h1 h2 h3 h4 h5 h6 h7 h8 br b i strong em a pre code img tt div ins del sup sub
    p ol ul table thead tbody tfoot blockquote dl dt dd kbd q samp var hr ruby rt
    rp li tr td th s strike summary details figure figcaption audio video source
    small iframe
  ]

  config.action_view.sanitized_allowed_attributes = %w[
    href src longdesc itemscope itemtype cite poster playsinline loop muted controls preload
    align width height abbr accept accept-charset accesskey action alt axis border cellpadding
    cellspacing char charoff charset checked clear cols colspan color compact
    coords datetime dir disabled enctype for frame headers height hreflang hspace
    ismap label lang maxlength media method multiple name nohref noshade nowrap
    open prompt readonly rel rev rows rowspan rules scope selected shape size span
    start summary tabindex target title type usemap valign value vspace width
    itemprop id
  ]
end
