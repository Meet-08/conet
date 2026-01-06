// const mongoose=require('mongoose');
// const { timestamp } = require('node:console');

// const postSchema=mongoose.Schema(
// {
//     name:{
//         type:String,
//         required:[true,"please add post name"],
//     },
//     description:{
//         type:String,
//         required:[true,"please enter description"],
//         // unique:[true,"email is already registered"],
//     },
//     like:{
//         type:Number,
//         default:0,
//     },
//     comment:{
//         type:String,

//     }



// },
// {
//     timestamp:true,
// }



// );

// module.exports= mongoose.model("user",postSchema);
const mongoose = require("mongoose");

const commentSchema = new mongoose.Schema(
  {
    text: {
      type: String,
      required: true,
    },
    user: {
      type: String, // later you can store userId
      default: "Anonymous",
    },
  },
  { timestamps: true }
);

const postSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },

    description: {
      type: String,
      required: true,
    },

    image: {
      type: String, // image URL or filename
      default: "",
    },

    likes: {
      type: [String], // store userId
      default: [],
    },
    comments: [commentSchema],
  },
  { timestamps: true }
);

module.exports = mongoose.model("Post", postSchema);
