# huffman

Huffman Encoding

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  huffman:
    github: chenkovsky/huffman
```

## Usage

```crystal
require "huffman"
  it "works" do
    symbols = ["F", "O", "R", "G", "E", "T"]
    freqs = [2, 3, 4, 4, 5, 7]
    huff = Huffman.compile(freqs)
    huff.path_codes.map { |_, _, bs| bs.map { |b| b ? "1" : "0" }.join("") }.should eq(["000", "100", "111", "011", "10", "01"])
  end
```

TODO: Write usage instructions here

## Development

TODO: Write development instructions here

## Contributing

1. Fork it (<https://github.com/chenkovsky/huffman/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [chenkovsky](https://github.com/chenkovsky) chenkovsky - creator, maintainer
