// api/create-checkout-session.js
// Función serverless para Vercel. Aquí SÍ vive la clave secreta de Stripe,
// nunca en el HTML/JS del navegador.
//
// Configuración necesaria en Vercel:
//   Project Settings > Environment Variables > STRIPE_SECRET_KEY = sk_live_... (o sk_test_... para pruebas)

import Stripe from 'stripe';

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'Método no permitido' });
    return;
  }

  const secretKey = process.env.STRIPE_SECRET_KEY;
  if (!secretKey) {
    res.status(500).json({ error: 'STRIPE_SECRET_KEY no configurada en el servidor' });
    return;
  }

  try {
    const stripe = new Stripe(secretKey);
    const { items, customerEmail } = req.body || {};

    if (!Array.isArray(items) || items.length === 0) {
      res.status(400).json({ error: 'Carrito vacío' });
      return;
    }

    // NOTA DE SEGURIDAD: esta versión confía en los precios que envía el
    // navegador. Antes de operar con dinero real, lo correcto es volver a
    // consultar el precio de cada producto en Supabase aquí mismo (con la
    // service_role key) y usar ESE precio, no el que llega del cliente.
    const line_items = items.map((it) => ({
      price_data: {
        currency: 'eur',
        product_data: { name: String(it.name || 'Producto Verdoro') },
        unit_amount: Math.round(Number(it.price) * 100),
      },
      quantity: Math.max(1, parseInt(it.qty) || 1),
    }));

    const origin = req.headers.origin || `https://${req.headers.host}`;

    const session = await stripe.checkout.sessions.create({
      mode: 'payment',
      line_items,
      customer_email: customerEmail || undefined,
      success_url: `${origin}/?paid=stripe&session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: `${origin}/?canceled=1`,
    });

    res.status(200).json({ url: session.url });
  } catch (err) {
    console.error('Stripe error:', err);
    res.status(500).json({ error: err.message });
  }
}
