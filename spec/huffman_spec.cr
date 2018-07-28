require "./spec_helper"

describe Huffman do
  # TODO: Write tests

  it "works" do
    symbols = ["F", "O", "R", "G", "E", "T"]
    freqs = [2, 3, 4, 4, 5, 7]
    huff = Huffman.compile(freqs)
    huff.path_codes.map { |_, _, bs| bs.map { |b| b ? "1" : "0" }.join("") }.should eq(["000", "100", "111", "011", "10", "01"])
  end
end
