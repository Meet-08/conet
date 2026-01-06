const mongoose=require('mongoose');
const { timeStamp } = require('node:console');

const userSchema=mongoose.Schema(
{
    username:{
        type:String,
        required:[true,"please add Your username"],
    },
    email:{
        type:String,
        required:[true,"please enter email_id"],
        unique:[true,"email is already registered"],
    },
    password:{
        type:String,
        required:[true,"please enter password"],
    },


},
{
    timestamp:true,
}



);

module.exports= mongoose.model("user",userSchema);