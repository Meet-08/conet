const express= require('express')

const{
createPost,
  updatePost,
  toggleLike,
  addComment,
  getAllPosts,
  editComment,

}=require('../controllers/postController.js');

const router=express.Router()


router.get('/',getAllPosts)
router.post('/',createPost)
router.put('/:id',updatePost)
router.put('/like/:id',toggleLike)
router.post('/comment/:id',addComment)

router.put('/:postId/comment/:commentId', editComment)



// router.put('/post',addComment)



module.exports = router;
