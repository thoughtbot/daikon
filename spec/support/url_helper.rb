module UrlHelper
  def infos_url(host = Daikon::Configuration::URL)
    "#{host}/api/v1/infos.json"
  end

  def summaries_url(host = Daikon::Configuration::URL)
    "#{host}/api/v1/summaries.json"
  end
end
