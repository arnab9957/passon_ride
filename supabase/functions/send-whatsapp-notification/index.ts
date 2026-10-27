// Supabase Edge Function: send-whatsapp-notification
// Sends automated messages via Meta WhatsApp Cloud API with server-side security.

// @ts-nocheck
import { serve } from 'https://deno.land/std@0.177.0/http/server.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
};

interface WhatsAppPayload {
  recipientPhone: string;
  templateName?: string;
  templateLanguage?: string;
  parameters?: string[];
  directMessageText?: string;
}

serve(async (req: Request) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const {
      recipientPhone,
      templateName,
      templateLanguage = 'en_US',
      parameters = [],
      directMessageText,
    }: WhatsAppPayload = await req.json();

    if (!recipientPhone) {
      return new Response(
        JSON.stringify({ success: false, error: 'Recipient phone number is required' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    // Clean phone number (remove +, spaces, hyphens)
    const cleanPhone = recipientPhone.replace(/[^0-9]/g, '');

    const token = Deno.env.get('WHATSAPP_CLOUD_API_TOKEN');
    const phoneNumberId = Deno.env.get('WHATSAPP_PHONE_NUMBER_ID');

    if (!token || !phoneNumberId) {
      return new Response(
        JSON.stringify({
          success: false,
          error: 'WhatsApp Cloud API credentials not configured in Supabase environment secrets (WHATSAPP_CLOUD_API_TOKEN, WHATSAPP_PHONE_NUMBER_ID).',
        }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    const apiUrl = `https://graph.facebook.com/v20.0/${phoneNumberId}/messages`;

    let bodyPayload: Record<string, unknown>;

    // 1. Template Message (Recommended for notifications & marketing)
    if (templateName) {
      const bodyComponents: Record<string, unknown>[] = [];
      if (parameters.length > 0) {
        bodyComponents.push({
          type: 'body',
          parameters: parameters.map((param) => ({
            type: 'text',
            text: String(param),
          })),
        });
      }

      bodyPayload = {
        messaging_product: 'whatsapp',
        to: cleanPhone,
        type: 'template',
        template: {
          name: templateName,
          language: { code: templateLanguage },
          components: bodyComponents,
        },
      };
    } else {
      // 2. Direct Text Message (Within 24-hr customer service window)
      bodyPayload = {
        messaging_product: 'whatsapp',
        recipient_type: 'individual',
        to: cleanPhone,
        type: 'text',
        text: {
          preview_url: true,
          body: directMessageText || 'Hello from PassionRide!',
        },
      };
    }

    const metaRes = await fetch(apiUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify(bodyPayload),
    });

    const metaData = await metaRes.json();

    if (!metaRes.ok) {
      return new Response(
        JSON.stringify({ success: false, error: metaData.error || 'Meta API error', details: metaData }),
        { status: metaRes.status, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      );
    }

    return new Response(
      JSON.stringify({ success: true, messageId: metaData.messages?.[0]?.id, data: metaData }),
      { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  } catch (error) {
    return new Response(
      JSON.stringify({ success: false, error: String(error) }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    );
  }
});
