namespace :photos do
  namespace :import do
    task :ids, [:file_to_use] => [:environment]  do |task, args|
      fh = File.open(args[:file_to_use], 'r')
      fh.each do |line|
        line.strip!
        DetailsImporter.perform_async(line)
      end
    end

    task :tag, [:tag_to_import] => [:environment] do |task,args|
      tag = args[:tag_to_import]
      rpp = 100
      
      results_page = $pixels_api.photos_by_tag(tag, {rpp: rpp, sort: "rating"})
      if results_page.total_pages == 0
        puts "No photos found for tag #{tag.inspect}"
        return
      end

      1.upto(results_page.total_pages).each do |page_num|
        puts "Fetching page #{page_num} for tag #{tag}"
        results_page = $pixels_api.photos_by_tag(tag, {rpp: rpp, page: page_num, sort: "rating"})
        results_page.photos.collect {|p| p.id }.each do |photo_id|
          DetailsImporter.perform_async(photo_id)
        end
      end
    end
  end
end