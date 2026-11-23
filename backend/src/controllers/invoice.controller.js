const PDFDocument = require('pdfkit');
const Payment = require('../models/Payment');
const { sendSuccess, sendError, sendNotFound } = require('../utils/response.utils');

// Generate and download invoice for a payment
const generateInvoice = async (req, res) => {
  try {
    const { paymentId } = req.params;
    
    console.log('generateInvoice called for payment ID:', paymentId);
    console.log('User ID:', req.user?.id);
    console.log('User role:', req.user?.role);

    // Find payment with populated data
    const payment = await Payment.findById(paymentId)
      .populate('userId', 'fullName email phone')
      .populate('courseId', 'title description price')
      .populate('schoolId', 'name')
      .populate('termId', 'academicYear term')
      .populate('adminApproval.approvedBy', 'fullName email');
    
    if (!payment) {
      console.log('Payment not found with ID:', paymentId);
      return sendNotFound(res, 'Payment not found');
    }

    // Students can only download their own invoice; admins can download any
    const isAdmin = req.user?.role === 'admin';
    const isOwner = payment.userId?._id?.toString() === req.user?.id?.toString() ||
                    payment.userId?.toString() === req.user?.id?.toString();
    if (!isAdmin && !isOwner) {
      console.log('Access denied: user', req.user?.id, 'tried to access invoice for payment owned by', payment.userId);
      return res.status(403).json({ success: false, message: 'Access denied. You can only download your own invoice.' });
    }

    console.log('Payment found:', payment.transactionId, 'Status:', payment.status);

    // Generate PDF invoice
    const pdfBuffer = await generatePDFInvoice(payment);

    // Set response headers for PDF download
    res.setHeader('Content-Type', 'application/pdf');
    res.setHeader('Content-Disposition', `attachment; filename="invoice_${payment.transactionId}.pdf"`);
    res.setHeader('Content-Length', pdfBuffer.length);

    // Send the PDF
    res.send(pdfBuffer);
    console.log('Invoice generated successfully for payment:', payment.transactionId);

  } catch (error) {
    console.error('Error in generateInvoice:', error);
    sendError(res, 'Failed to generate invoice', 500, error.message);
  }
};

// Generate PDF invoice using PDFKit (no Chrome/Puppeteer required)
function generatePDFInvoice(payment) {
  return new Promise((resolve, reject) => {
    try {
      const doc = new PDFDocument({ margin: 50, size: 'A4' });
      const chunks = [];
      doc.on('data', chunk => chunks.push(chunk));
      doc.on('end', () => resolve(Buffer.concat(chunks)));
      doc.on('error', reject);

      const ACCENT  = '#2ecc71';
      const DARK    = '#2c3e50';
      const GREY    = '#7f8c8d';
      const LIGHT   = '#f8f9fa';
      const pageW   = doc.page.width - 100; // usable width with 50px margins each side
      const M       = 50;                   // left margin

      const dateStr = new Date().toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' });
      const payDate = payment.paymentDate
        ? new Date(payment.paymentDate).toLocaleDateString('en-US', { year: 'numeric', month: 'long', day: 'numeric' })
        : 'Pending';
      const amtStr  = `${payment.amount} ${payment.currency}`;

      // ── Header bar ──────────────────────────────────────────────────────────
      doc.rect(M, 45, pageW, 60).fill(ACCENT);
      doc.fillColor('#ffffff').fontSize(22).font('Helvetica-Bold').text('INVOICE', M + 10, 62);
      doc.fontSize(10).font('Helvetica').text(`#${payment.transactionId}`, M + 10, 84);
      doc.text(`Date: ${dateStr}`, M, 84, { align: 'right', width: pageW });

      // ── Company info ────────────────────────────────────────────────────────
      doc.fillColor(DARK).fontSize(15).font('Helvetica-Bold').text('Excellence Coaching Hub', M, 128);
      doc.fillColor(GREY).fontSize(10).font('Helvetica')
        .text('Kigali, Rwanda', M, 148)
        .text('info@excellencecoachinghub.com', M, 161)
        .text('+250 788 535 156  /  +250 793 828 834', M, 174);

      // ── Divider ─────────────────────────────────────────────────────────────
      doc.moveTo(M, 196).lineTo(M + pageW, 196).strokeColor(ACCENT).lineWidth(1.5).stroke();

      // ── Bill To / Payment Details ────────────────────────────────────────────
      const col2 = M + pageW / 2 + 10;
      doc.fillColor(DARK).fontSize(11).font('Helvetica-Bold').text('BILL TO:', M, 210);
      doc.text('PAYMENT DETAILS:', col2, 210);
      doc.fillColor(DARK).fontSize(10).font('Helvetica-Bold').text(payment.userId?.fullName || 'Unknown User', M, 228);
      doc.fillColor(GREY).fontSize(10).font('Helvetica')
        .text(payment.userId?.email || '', M, 242)
        .text(payment.userId?.phone || '', M, 256);
      doc.fillColor(GREY).fontSize(10).font('Helvetica')
        .text(`Method: ${payment.paymentMethod || '-'}`, col2, 228)
        .text(`Payment Date: ${payDate}`, col2, 242)
        .text(`Status: ${payment.status}`, col2, 256);

      // ── Table header ─────────────────────────────────────────────────────────
      const tTop = 284;
      doc.rect(M, tTop, pageW, 22).fill(ACCENT);
      doc.fillColor('#ffffff').fontSize(10).font('Helvetica-Bold');
      doc.text('Description', M + 8, tTop + 6, { width: 280 });
      doc.text('Qty',         M + 300, tTop + 6, { width: 40,  align: 'center' });
      doc.text('Unit Price',  M + 350, tTop + 6, { width: 90,  align: 'right'  });
      doc.text('Total',       M + 450, tTop + 6, { width: 60,  align: 'right'  });

      // ── Table row ─────────────────────────────────────────────────────────────
      const rTop = tTop + 22;
      doc.rect(M, rTop, pageW, 26).fill(LIGHT);
      doc.fillColor(DARK).fontSize(10).font('Helvetica');
      const itemLabel = payment.purpose === 'school_term'
        ? `${payment.schoolId?.name || 'School'} · ${payment.termId ? `${payment.termId.academicYear} Term ${payment.termId.term}` : 'Term'} · ${payment.seats || 0} students`
        : payment.purpose === 'teacher_guide'
          ? `Teacher's guide: ${payment.courseId?.title || 'Course'}`
          : (payment.courseId?.title || 'Course');
      doc.text(itemLabel, M + 8, rTop + 8, { width: 280, ellipsis: true });
      doc.text('1',     M + 300, rTop + 8, { width: 40,  align: 'center' });
      doc.text(amtStr,  M + 350, rTop + 8, { width: 90,  align: 'right'  });
      doc.text(amtStr,  M + 450, rTop + 8, { width: 60,  align: 'right'  });

      // ── Transaction ID ────────────────────────────────────────────────────────
      doc.fillColor(GREY).fontSize(9).font('Helvetica')
        .text(`Transaction ID: ${payment.transactionId}`, M, rTop + 40);

      // ── Totals box ────────────────────────────────────────────────────────────
      const bTop = rTop + 40;
      const bX   = M + pageW - 230;
      doc.rect(bX, bTop, 230, 88).fill(LIGHT).strokeColor(ACCENT).lineWidth(1).stroke();
      doc.fillColor(GREY).fontSize(10).font('Helvetica')
        .text('Subtotal:', bX + 12, bTop + 12)
        .text('Tax (0%):', bX + 12, bTop + 30);
      doc.fillColor(DARK).font('Helvetica-Bold')
        .text(amtStr,             bX + 12, bTop + 12, { align: 'right', width: 206 })
        .text(`0 ${payment.currency}`, bX + 12, bTop + 30, { align: 'right', width: 206 });
      doc.moveTo(bX + 12, bTop + 52).lineTo(bX + 218, bTop + 52).strokeColor(ACCENT).lineWidth(1).stroke();
      doc.fillColor(ACCENT).fontSize(12).font('Helvetica-Bold')
        .text('TOTAL:', bX + 12, bTop + 60)
        .text(amtStr,   bX + 12, bTop + 60, { align: 'right', width: 206 });

      // ── Footer ────────────────────────────────────────────────────────────────
      const fY = doc.page.height - 70;
      doc.moveTo(M, fY).lineTo(M + pageW, fY).strokeColor('#ecf0f1').lineWidth(1).stroke();
      doc.fillColor(GREY).fontSize(9).font('Helvetica')
        .text('Thank you for choosing Excellence Coaching Hub!', M, fY + 10, { align: 'center', width: pageW })
        .text('This is a computer-generated invoice and does not require a signature.', M, fY + 24, { align: 'center', width: pageW });

      doc.end();
    } catch (err) {
      reject(err);
    }
  });
}

module.exports = {
  generateInvoice
};
