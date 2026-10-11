require 'rails_helper'

RSpec.describe BlueskyService, type: :service do
  # .allocate skips #initialize, which reaches out to Rails.cache/credentials -
  # link_facets and tag_facets are pure string parsing and don't need that setup.
  let(:service) { described_class.allocate }

  describe '#link_facets' do
    it 'finds a single http(s) link and returns its byte offsets and uri' do
      message = 'Check out https://example.com for more info'

      facets = service.send(:link_facets, message)

      expect(facets).to eq(
        [
          {
            'index' => { 'byteStart' => 10, 'byteEnd' => 29 },
            'features' => [{ 'uri' => 'https://example.com', '$type' => 'app.bsky.richtext.facet#link' }]
          }
        ]
      )
    end

    it 'finds multiple links in the same message' do
      message = 'See https://a.com and https://b.org/path?x=1 too'

      facets = service.send(:link_facets, message)

      expect(facets.map { |f| f['features'].first['uri'] }).to eq(['https://a.com', 'https://b.org/path?x=1'])
    end

    it 'returns an empty array when there are no links' do
      expect(service.send(:link_facets, 'No links in this message')).to eq([])
    end

    it 'does not swallow trailing punctuation or a closing quote into the uri' do
      message = 'See this: "https://example.com/path", great'

      facets = service.send(:link_facets, message)

      expect(facets.first['features'].first['uri']).to eq('https://example.com/path')
    end

    it 'computes byte offsets (not character offsets) when the message has multi-byte characters' do
      message = 'Déjà vu: https://example.com here'

      facets = service.send(:link_facets, message)

      start, stop = facets.first['index'].values_at('byteStart', 'byteEnd')
      expect(message.b[start...stop]).to eq('https://example.com')
    end
  end

  describe '#tag_facets' do
    it 'finds hashtags and returns their byte offsets and tag text, without the #' do
      message = 'Big news on #auspol today'

      facets = service.send(:tag_facets, message)

      expect(facets).to eq(
        [
          {
            'index' => { 'byteStart' => 12, 'byteEnd' => 19 },
            'features' => [{ 'tag' => 'auspol', '$type' => 'app.bsky.richtext.facet#tag' }]
          }
        ]
      )
    end

    it 'returns an empty array when there are no hashtags' do
      expect(service.send(:tag_facets, 'nothing to tag here')).to eq([])
    end
  end

  describe '#skeet' do
    it 'posts the message with link and tag facets and returns the created record uri' do
      allow(service).to receive(:verify_tokens)
      allow(service).to receive(:post_request).and_return({ 'uri' => 'at://did:plc:abc/app.bsky.feed.post/123' })

      result = service.skeet('See https://example.com #news')

      expect(result).to eq('at://did:plc:abc/app.bsky.feed.post/123')
      expect(service).to have_received(:post_request).with(
        a_string_ending_with('com.atproto.repo.createRecord'),
        body: hash_including(
          record: hash_including(
            text: 'See https://example.com #news',
            facets: array_including(
              hash_including('features' => [{ 'uri' => 'https://example.com', '$type' => 'app.bsky.richtext.facet#link' }]),
              hash_including('features' => [{ 'tag' => 'news', '$type' => 'app.bsky.richtext.facet#tag' }])
            )
          )
        )
      )
    end
  end
end
