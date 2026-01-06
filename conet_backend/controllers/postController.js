const asyncHandler = require("express-async-handler");
const Post = require("../models/post");

// CREATE POST
const createPost = asyncHandler(async (req, res) => {
  const { name, description, image } = req.body;

  if (!name || !description) {
    res.status(400);
    throw new Error("Name and description are required");
  }

  const post = await Post.create({
    name,
    description,
    image, // image URL or filename
  });

  res.status(201).json({
    success: true,
    message: "Post created successfully",
    post,
  });
});



// UPDATE POST
const updatePost = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { name, description, image } = req.body;

  const post = await Post.findByIdAndUpdate(
    id,
    {
      name,
      description,
      image,
    },
    { new: true }
  );

  if (!post) {
    res.status(404);
    throw new Error("Post not found");
  }

  res.status(200).json({
    success: true,
    message: "Post updated successfully",
    post,
  });
});

// // LIKE POST
// const likePost = asyncHandler(async (req, res) => {
//   const { id } = req.params;

//   const post = await Post.findById(id);

//   if (!post) {
//     res.status(404);
//     throw new Error("Post not found");
//   }

//   post.likes += 1;
//   await post.save();

//   res.json({
//     success: true,
//     likes: post.likes,
//   });
// });

const toggleLike = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const userId = req.body.userId; // later from auth

  const post = await Post.findById(id);
  if (!post) {
    res.status(404);
    throw new Error("Post not found");
  }

  const isLiked = post.likes.includes(userId);

  if (isLiked) {
    // DISLIKE (remove like)
    post.likes = post.likes.filter((uid) => uid !== userId);
  } else {
    // LIKE
    post.likes.push(userId);
  }

  await post.save();

  res.json({
    success: true,
    liked: !isLiked,
    totalLikes: post.likes.length,
  });
});

// ADD COMMENT
const addComment = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { text, user } = req.body;

  if (!text) {
    res.status(400);
    throw new Error("Comment text required");
  }

  const post = await Post.findById(id);

  if (!post) {
    res.status(404);
    throw new Error("Post not found");
  }

  post.comments.push({
    text,
    user,
  });

  await post.save();

  res.json({
    success: true,
    comments: post.comments,
  });






});



const getAllPosts = asyncHandler(async (req, res) => {
  const posts = await Post.find()
    .sort({ createdAt: -1 }); // 🔥 newest first

  res.status(200).json({
    success: true,
    count: posts.length,
    posts,
  });
});
const editComment = asyncHandler(async (req, res) => {
  const { postId, commentId } = req.params;
  const { text } = req.body;

  if (!text) {
    res.status(400);
    throw new Error("Comment text is required");
  }

  const post = await Post.findById(postId);

  if (!post) {
    res.status(404);
    throw new Error("Post not found");
  }

  // find comment inside post
  const comment = post.comments.id(commentId);

  if (!comment) {
    res.status(404);
    throw new Error("Comment not found");
  }

  // update comment
  comment.text = text;

  await post.save();

  res.json({
    success: true,
    message: "Comment updated successfully",
    comment,
  });
});


module.exports = {
  createPost,
  updatePost,
  toggleLike,
  addComment,
  getAllPosts,
  editComment,
};
