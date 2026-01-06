const express=require('express')
const connectdb=require('./config/db.js')
const errorhandler=require('./middleware/errorhandler.js')
require('dotenv').config();
const userroutes=require('./routes/userRoutes.js');
const postroutes=require('./routes/postRoutes.js');

connectdb();

const app=express();

const port=process.env.PORT || 5000;


app.use(express.json())
app.use('/api/user',userroutes)
app.use('/api/posts',postroutes)
// app.use(errorhandler)

app.listen(port,()=>{
    console.log(`server is running on port ${port}`);
})