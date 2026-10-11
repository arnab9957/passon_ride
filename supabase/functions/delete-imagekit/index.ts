// @ts-ignore
declare const Deno: any;
import "@supabase/functions-js/edge-runtime.d.ts";

const IMAGEKIT_PRIVATE_KEY = Deno.env.get('IMAGEKIT_PRIVATE_KEY') || 'private_5/fwszcSPz24H6XDv/4V3gyiUk0=';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req: any) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { fileUrl } = await req.json();

    if (!fileUrl) {
      return new Response(JSON.stringify({ error: 'fileUrl is required' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // Extract filename from URL
    const urlParts = new URL(fileUrl).pathname.split('/');
    let fileName = urlParts[urlParts.length - 1];

    if (!fileName) {
      return new Response(JSON.stringify({ error: 'Could not extract fileName' }), {
        status: 400,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    // ImageKit Search API requires Basic Auth
    const authHeader = 'Basic ' + btoa(IMAGEKIT_PRIVATE_KEY + ':');

    // 1. Search for the fileId
    const searchUrl = `https://api.imagekit.io/v1/files?searchQuery=name="${fileName}"`;
    const searchRes = await fetch(searchUrl, {
      headers: {
        'Authorization': authHeader
      }
    });

    if (!searchRes.ok) {
      const err = await searchRes.text();
      throw new Error(`Failed to search ImageKit: ${err}`);
    }

    const searchData = await searchRes.json();
    if (!searchData || searchData.length === 0) {
      return new Response(JSON.stringify({ message: 'File not found in ImageKit, skipping delete.' }), {
        status: 200,
        headers: { ...corsHeaders, 'Content-Type': 'application/json' }
      });
    }

    const fileId = searchData[0].fileId;

    // 2. Delete the file by fileId
    const deleteUrl = `https://api.imagekit.io/v1/files/${fileId}`;
    const deleteRes = await fetch(deleteUrl, {
      method: 'DELETE',
      headers: {
        'Authorization': authHeader
      }
    });

    if (!deleteRes.ok) {
      const err = await deleteRes.text();
      throw new Error(`Failed to delete from ImageKit: ${err}`);
    }

    return new Response(JSON.stringify({ message: 'Successfully deleted from ImageKit' }), {
      status: 200,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });

  } catch (error: any) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' }
    });
  }
});
