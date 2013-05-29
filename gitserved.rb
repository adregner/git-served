#!/usr/bin/env ruby
require 'sinatra'
require 'uri'
require 'rugged'
require 'filemagic'
require 'yaml'

Config = YAML.load_file 'config.yaml'

get '/*' do
  path = request.env["PATH_INFO"].split('/')[1..-1].reverse rescue []
  item = nil
  repo = nil
  history_list = Dir["#{Config[:git_root]}/*"].map{|d| d.split('/')[-1] }

  itters = 1

  while path.count > 0
    name = path.pop
    next if not name
    puts "popped off #{name.inspect} with #{path.count} left"
    name = URI.decode_www_form_component(name) if name.include? '%'

    # step 1
    if item.nil?
      repo = Rugged::Repository.new(File.join(Config[:git_root], name)) rescue nil
      item = repo
    end

    # step 3
    if ["branch", "tag"].include? name and path.count > 0
      reftype = name == 'tag' ? 'tags' : 'heads'
      item = Rugged::Reference.lookup(repo, "refs/#{reftype}/#{path.pop}") rescue nil
      history_list = repo.lookup(item.target).tree.collect{|i| i[:name] + (i[:type] == :tree ? '/' : '') }

    # step 2
    elsif item.class == Rugged::Repository
      reftype = name == 'tag' ? 'tags' : 'heads'
      filter = if ["branch", "tag"].include? name
                 /^refs\/#{reftype}/
               else
                 /^/
               end
      history_list = repo.refs.sort.select{|ref| ref.match filter }.collect do |ref|
        reftype = ref.split('/')[1]
        ref.sub /^refs\/#{reftype}/, (reftype == 'tags' ? 'tag' : 'branch')
      end

    # step 4
    elsif item.class == Rugged::Reference
      sha = item.target
      tree = repo.lookup(sha).tree
      item = repo.lookup( tree.select{|i| i[:name] == name }.first[:oid] )
      history_list = item.collect{|i| i[:name] + (i[:type] == :tree ? '/' : '') } unless item.class == Rugged::Blob

    # step 5
    elsif item.class == Rugged::Tree
      item = repo.lookup( item.select{|i| i[:name] == name }.first[:oid] )
      history_list = item.collect{|i| i[:name] + (i[:type] == :tree ? '/' : '') } unless item.class == Rugged::Blob

    else
      break # let the handlers below handle showing what we got
    end

    if item.nil?
      break # something wasn't found...
    elsif item.class == Array
      break if item.count > 1
      item = item.first
    end

    puts "got #{item.inspect} on itteration #{itters}"
    itters += 1

    if itters > 10
      puts "OMG OOPS"
      break
    end
  end

  if item.class == Rugged::Blob
    raw = item.read_raw
    mimetype = FileMagic.mime.buffer(raw.data)
    return [200, {"Content-type" => mimetype}, raw.data]
  else
    base = request.env["PATH_INFO"].chomp('/')
    up = base.split('/')[0..-2].join('/')
    up = '/' if up == ''
    base += '/' if base != '/'
    return "<pre><a href=\"#{up}\">Up one level...</a>\n\n" +
      history_list.collect do |name|
        "<a href=\"#{base}#{name}\">#{name}</a>"
      end.join("\n")
  end
end
