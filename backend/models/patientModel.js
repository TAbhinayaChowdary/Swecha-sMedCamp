const mongoose = require('mongoose');

const PatientSchema = new mongoose.Schema({
    book_no: { type: String, required: true, unique: true },
    patient_name: { type: String, required: false },
    patient_age: { type: Number, required: false },
    patient_sex: { type: String, required: false },
    patient_phone_no: { type: String, required: false },
    patient_area: { type: String, required: false },
  });
  
const Patient = mongoose.model('Patient', PatientSchema);

module.exports = Patient;