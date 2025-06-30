const mongoose = require('mongoose');
require('dotenv').config();

// Connect to MongoDB
mongoose.connect(process.env.MONGO_URI || "mongodb+srv://s25dassteam24:EcI2NdEIA0a95sd2@team-24.km4p9.mongodb.net/?retryWrites=true&w=majority&appName=team-24");

const User = require('./models/userModel');

async function testLogin() {
    try {
        console.log('Testing admin login...');
        
        // Check all admin users
        const adminUsers = await User.find({ user_type: 'admin' });
        console.log('Admin users found:', adminUsers.length);
        adminUsers.forEach(user => {
            console.log('Admin user:', {
                user_name: user.user_name,
                user_type: user.user_type,
                user_id: user.user_id,
                has_password: !!user.user_password
            });
        });
        
        // Test login with admin123
        const user = await User.findOne({ user_name: 'admin123', user_type: 'admin' });
        if (user) {
            console.log('Found user:', user.user_name);
            console.log('Password match:', 'admin123' === user.user_password);
            console.log('User type:', user.user_type);
        } else {
            console.log('User not found');
        }
        
    } catch (error) {
        console.error('Error:', error);
    } finally {
        mongoose.connection.close();
    }
}

testLogin(); 