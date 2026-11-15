const inr = new Intl.NumberFormat('en-IN', { maximumFractionDigits: 0 });

/** 150000 -> "₹1,50,000" (Indian digit grouping). */
export const formatInr = (amount) => `₹${inr.format(amount)}`;

/** "ABCPE1234F" -> "AB******4F" */
export const maskPan = (pan) => (pan ? `${pan.slice(0, 2)}******${pan.slice(-2)}` : null);

/** "123456789012" -> "XXXX XXXX 9012" */
export const maskTail = (value, visible = 4) => (value ? `XXXX${value.slice(-visible)}` : null);
