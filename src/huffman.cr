require "./huffman/*"

# TODO: Write documentation for `Huffman`
class Huffman
  struct Node
    @parent : Int32
    @left : Int32
    @right : Int32
    @count : Int64
    @binary : Bool
    property :parent, :left, :right, :count, :binary

    def initialize(@parent = -1, @left = -1, @right = -1, @count = Int64::MAX, @binary = false)
    end

    def leaf?
      @left == -1 || @right == -1
    end

    def to_io(io : IO, format : IO::ByteFormat)
      @parent.to_io io, format
      @left.to_io io, format
      @right.to_io io, format
      @count.to_io io, format
      (@binary ? 1_u8 : 0_u8).to_io io, format
    end

    def self.from_io(io : IO, format : IO::ByteFormat)
      parent = Int32.from_io io, format
      left = Int32.from_io io, format
      right = Int32.from_io io, format
      count = Int64.from_io io, format
      binary = (UInt8.from_io io, format) != 0_u8
      return Node.new(parent, left, right, count, binary)
    end
  end

  @tree : Array(Node)
  @leaf_num : Int32
  @ids : Array(Int32)?
  getter :leaf_num

  def to_io(io : IO, format : IO::ByteFormat)
    @leaf_num.to_io io, format
    @tree.size.to_io io, format
    (0...@tree.size).each do |i|
      (@tree.to_unsafe + i).value.to_io(io, format)
    end
    if @ids.nil?
      0.to_io io, format
    else
      @ids.size.to_io io, format
      @ids.each { |id| id.to_io io, format }
    end
  end

  def self.from_io(io : IO, format : IO::ByteFormat)
    leaf_num = Int32.from_io io, format
    tree_size = Int32.from_io io, format
    tree = (0...tree_size).map { |_| Node.from_io io, format }
    ids_num = Int32.from_io io, format
    if ids_num == 0
      ids = nil
    else
      ids = (0...ids_num).map { |_| Int32.from_io io, format }
    end
    return Huffman.new(tree, ids, leaf_num)
  end

  def initialize(@tree, @ids, @leaf_num)
  end

  def path_code(id : Int32)
    raise IndexError.new if id >= @leaf_num
    node_ptr = node(id)
    path = [] of Int32
    code = [] of Bool
    while node_ptr.value.parent != -1
      path << (node_ptr.value.parent - @leaf_num)
      code << node_ptr.value.binary
      node_ptr = node(node_ptr.value.parent)
    end
    return path, code
  end

  def path_codes
    (0...@leaf_num).each do |i|
      path, code = path_code(i)
      yield i, path, code
    end
  end

  def path_codes
    ret = [] of Tuple(Int32, Array(Int32), Array(Bool))
    path_codes do |i, path, code|
      ret << ({i, path, code})
    end
    return ret
  end

  {% for name, idx in [:leaf?, :count, :left, :right, :binary] %}
  def {{name.id}}(id : Int32)
    node(id).value.{{name.id}}
  end
  {% end %}

  def node(id : Int32) : Pointer(Node)
    raise IndexError.new if id >= @tree.size
    ids = @ids
    if !ids.nil? && id < ids.size
      id = ids[id]
    end
    @tree.to_unsafe + id
  end

  def self.compile(counts : Array(Int32), desc : Bool = false)
    self.compile(counts.map { |c| c.to_i64 }, desc)
  end

  def self.compile(counts : Array(Int64), desc : Bool = false)
    unless desc
      cnt_idx_to_ids = Array.new(counts.size) { |i| i }
      cnt_idx_to_ids.sort_by! { |i| -counts[i] }
      ids = Array.new(counts.size, 0)
      cnt_idx_to_ids.each_with_index do |id, idx|
        ids[id] = idx
      end
      counts = counts.sort_by { |c| -c }
    else
      ids = nil
    end
    tree = desc_compile(counts)
    Huffman.new(tree, ids, counts.size)
  end

  private def self.desc_compile(counts : Array(Int64))
    # assume counts is desc ordered
    osz = counts.size
    nodes_size = 2 * osz - 1
    tree = Array(Node).new(nodes_size, Node.new)
    counts.each_with_index do |cnt, idx|
      node_ptr = tree.to_unsafe + idx
      node_ptr.value.count = cnt
      node_ptr.value.left = idx
    end
    leaf = osz - 1
    node = osz
    (osz...nodes_size).each do |i|
      mini = StaticArray(Int32, 2).new(-1)
      (0...2).each do |j|
        if leaf >= 0 && (tree.to_unsafe + leaf).value.count < (tree.to_unsafe + node).value.count
          mini[j] = leaf
          leaf -= 1
        else
          mini[j] = node
          node += 1
        end
      end
      node_ptr = tree.to_unsafe + i
      left_ptr = tree.to_unsafe + mini[0]
      right_ptr = tree.to_unsafe + mini[1]
      node_ptr.value.left = mini[0]
      node_ptr.value.right = mini[1]
      node_ptr.value.count = left_ptr.value.count + right_ptr.value.count

      left_ptr.value.parent = i
      right_ptr.value.parent = i
      right_ptr.value.binary = true
    end
    return tree
  end
end
