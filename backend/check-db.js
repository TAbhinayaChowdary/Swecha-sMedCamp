const mongoose = require('mongoose');
require('dotenv').config();

async function checkDatabase() {
    try {
        console.log('Checking database...');
        console.log('Connection string:', process.env.MONGO_URI || "mongodb+srv://s25dassteam24:EcI2NdEIA0a95sd2@team-24.km4p9.mongodb.net/?retryWrites=true&w=majority&appName=team-24");
        
        // Connect to MongoDB
        await mongoose.connect(process.env.MONGO_URI || "mongodb+srv://s25dassteam24:EcI2NdEIA0a95sd2@team-24.km4p9.mongodb.net/?retryWrites=true&w=majority&appName=team-24");
        
        console.log('Connected to database:', mongoose.connection.db.databaseName);
        
        const User = require('./models/userModel');
        
        // Check all users
        const allUsers = await User.find({});
        console.log('Total users found:', allUsers.length);
        
        allUsers.forEach(user => {
            console.log('User:', {
                _id: user._id,
                user_name: user.user_name,
                user_type: user.user_type,
                user_id: user.user_id
            });
        });
        
        // Check admin users specifically
        const adminUsers = await User.find({ user_type: 'admin' });
        console.log('Admin users found:', adminUsers.length);
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        await mongoose.connection.close();
    }
}

checkDatabase(); 