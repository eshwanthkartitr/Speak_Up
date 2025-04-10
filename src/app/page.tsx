'use client';

import React, { useEffect, useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

interface Summary {
  total_signs_processed: number;
  average_accuracy: number;
  active_users: number;
  avg_processing_time: number;
}

interface Detection {
  sign: string;
  timestamp: string;
  confidence: number;
}

interface AccuracyPoint {
  date: string;
  accuracy: number;
}

export default function DashboardPage() {
  const [summary, setSummary] = useState<Summary | null>(null);
  const [recentDetections, setRecentDetections] = useState<Detection[]>([]);
  const [accuracyTrend, setAccuracyTrend] = useState<AccuracyPoint[]>([]);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    const fetchData = async () => {
      try {
        // Fetch summary data
        const summaryRes = await fetch('/api/analytics/summary');
        if (!summaryRes.ok) throw new Error('Failed to fetch summary');
        const summaryData = await summaryRes.json();
        setSummary(summaryData);

        // Fetch recent detections
        const detectionsRes = await fetch('/api/analytics/recent-detections');
        if (!detectionsRes.ok) throw new Error('Failed to fetch recent detections');
        const detectionsData = await detectionsRes.json();
        setRecentDetections(detectionsData);

        // Fetch accuracy trend
        const trendRes = await fetch('/api/analytics/accuracy-trend');
        if (!trendRes.ok) throw new Error('Failed to fetch accuracy trend');
        const trendData = await trendRes.json();
        setAccuracyTrend(trendData);
      } catch (err) {
        setError(err instanceof Error ? err.message : 'An error occurred');
      }
    };

    fetchData();
    const interval = setInterval(fetchData, 5000); // Refresh every 5 seconds

    return () => clearInterval(interval);
  }, []);

  if (error) {
    return (
      <div className="p-4">
        <div className="text-red-500">Error: {error}</div>
      </div>
    );
  }

  return (
    <main className="p-4">
      <div className="grid gap-4 md:grid-cols-4">
        <Card>
          <CardHeader>
            <CardTitle>Total Signs Processed</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {summary?.total_signs_processed?.toLocaleString() ?? '0'}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Average Accuracy</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {summary?.average_accuracy?.toFixed(1) ?? '0'}%
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Active Users</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {summary?.active_users ?? '0'}
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Avg. Processing Time</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">
              {summary?.avg_processing_time?.toFixed(2) ?? '0.00'}s
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="mt-8">
        <h2 className="text-xl font-bold mb-4">Accuracy Trend</h2>
        <Card>
          <CardContent className="pt-6">
            <div className="h-[300px]">
              <ResponsiveContainer width="100%" height="100%">
                <LineChart data={accuracyTrend}>
                  <CartesianGrid strokeDasharray="3 3" />
                  <XAxis dataKey="date" />
                  <YAxis domain={[80, 100]} />
                  <Tooltip />
                  <Line type="monotone" dataKey="accuracy" stroke="#8884d8" />
                </LineChart>
              </ResponsiveContainer>
            </div>
          </CardContent>
        </Card>
      </div>

      <div className="mt-8">
        <h2 className="text-xl font-bold mb-4">Recent Detections</h2>
        <div className="space-y-4">
          {recentDetections.map((detection, index) => (
            <Card key={index}>
              <CardContent className="py-4">
                <div className="flex justify-between items-center">
                  <div>
                    <div className="font-bold">{detection.sign}</div>
                    <div className="text-sm text-gray-500">
                      {new Date(detection.timestamp).toLocaleString()}
                    </div>
                  </div>
                  <div className="text-green-600">
                    {(detection.confidence * 100).toFixed(1)}% confidence
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      </div>
    </main>
  );
} 