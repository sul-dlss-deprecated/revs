desc "Cleanup solr documents by removing extra spaces in format fields"
task :cleanup_solr do
  
  formats_to_cleanup=["black-and-white film ","black-and-white negatives/color negatives "]
  
  formats_to_cleanup.each do |format_to_cleanup|
    results=Blacklight.solr.select(:params => {:fq=>'format_ssim:"' + format_to_cleanup + '"',:rows=>'10000'})
    puts "Found #{results['response']['docs'].size} documents with '#{format_to_cleanup}'"
    results['response']['docs'].each do |result|
      result.delete("timestamp")
      result.delete("_version_")
      result["format_ssim"]=[format_to_cleanup.strip]
      Blacklight.solr.add(result)
      puts "Updating #{result["id"]}"
    end
    Blacklight.solr.commit
  end
  
end