import React, { useState, useMemo } from 'react';
import {
  LineChart, Line, BarChart, Bar, PieChart, Pie, Cell,
  ResponsiveContainer, XAxis, YAxis, CartesianGrid, Tooltip, Legend, RadarChart, Radar, PolarGrid, PolarAngleAxis, PolarRadiusAxis
} from 'recharts';
import { TrendingUp, TrendingDown, Users, Zap, Package, Calendar, Download, Phone, Code, ArrowUpRight, ArrowDownRight, Menu, X } from 'lucide-react';

// ============================================================================
// SIMULATED DATA
// ============================================================================

const brandData = [
  { name: 'Ganni', affinity: 8.7, trendDirection: 'up', swipeToSave: 34.2, priceSensitivity: 'Medium', swipes: 18420, saves: 6290, color: '#E74C3C' },
  { name: 'Staud', affinity: 8.4, trendDirection: 'up', swipeToSave: 31.8, priceSensitivity: 'Medium-High', swipes: 16850, saves: 5370, color: '#3498DB' },
  { name: 'Nanushka', affinity: 8.1, trendDirection: 'up', swipeToSave: 28.9, priceSensitivity: 'High', swipes: 14720, saves: 4250, color: '#2ECC71' },
  { name: 'Reformation', affinity: 7.9, trendDirection: 'stable', swipeToSave: 26.4, priceSensitivity: 'Medium', swipes: 13340, saves: 3520, color: '#F39C12' },
  { name: 'Deiji Studios', affinity: 7.6, trendDirection: 'up', swipeToSave: 23.7, priceSensitivity: 'Medium-High', swipes: 12140, saves: 2880, color: '#9B59B6' },
  { name: 'The Row', affinity: 7.8, trendDirection: 'stable', swipeToSave: 19.2, priceSensitivity: 'Very High', swipes: 10920, saves: 2090, color: '#34495E' },
  { name: 'Khaite', affinity: 8.0, trendDirection: 'up', swipeToSave: 21.5, priceSensitivity: 'Very High', swipes: 11780, saves: 2530, color: '#E67E22' },
  { name: 'Jacquemus', affinity: 7.7, trendDirection: 'up', swipeToSave: 24.1, priceSensitivity: 'High', swipes: 12590, saves: 3040, color: '#1ABC9C' },
  { name: 'Sandy Liang', affinity: 7.4, trendDirection: 'up', swipeToSave: 29.3, priceSensitivity: 'Low-Medium', swipes: 11240, saves: 3290, color: '#C0392B' },
  { name: 'Collina Strada', affinity: 7.2, trendDirection: 'down', swipeToSave: 22.6, priceSensitivity: 'Medium', swipes: 9340, saves: 2110, color: '#16A085' },
  { name: 'Rixo', affinity: 6.9, trendDirection: 'down', swipeToSave: 18.4, priceSensitivity: 'Medium', swipes: 8120, saves: 1500, color: '#8E44AD' },
  { name: 'Self-Portrait', affinity: 7.0, trendDirection: 'stable', swipeToSave: 20.1, priceSensitivity: 'High', swipes: 8950, saves: 1800, color: '#27AE60' },
  { name: 'Maje', affinity: 6.8, trendDirection: 'down', swipeToSave: 17.3, priceSensitivity: 'Low-Medium', swipes: 7890, saves: 1365, color: '#D35400' },
  { name: 'SSENSE Exclusive', affinity: 7.5, trendDirection: 'up', swipeToSave: 25.8, priceSensitivity: 'Medium-High', swipes: 11450, saves: 2960, color: '#2C3E50' },
  { name: 'Farfetch Curated', affinity: 7.3, trendDirection: 'up', swipeToSave: 23.2, priceSensitivity: 'High', swipes: 10240, saves: 2375, color: '#16A085' },
  { name: 'Browns Fashion', affinity: 7.1, trendDirection: 'stable', swipeToSave: 19.8, priceSensitivity: 'Very High', swipes: 8670, saves: 1715, color: '#8B4513' },
  { name: 'Dover Street Market', affinity: 7.4, trendDirection: 'up', swipeToSave: 26.1, priceSensitivity: 'High', swipes: 10890, saves: 2840, color: '#000000' },
  { name: 'Atelier New Regime', affinity: 6.7, trendDirection: 'stable', swipeToSave: 21.4, priceSensitivity: 'Medium-High', swipes: 7560, saves: 1620, color: '#E74C3C' },
  { name: 'Lemaire', affinity: 6.9, trendDirection: 'down', swipeToSave: 17.9, priceSensitivity: 'Very High', swipes: 7230, saves: 1295, color: '#3498DB' },
  { name: 'Totême', affinity: 7.0, trendDirection: 'stable', swipeToSave: 18.7, priceSensitivity: 'High', swipes: 7890, saves: 1475, color: '#2ECC71' },
];

const trendData = [
  { week: 'W1', Loungewear: 42, Knitwear: 38, Denim: 45, Dresses: 52, Outerwear: 28 },
  { week: 'W2', Loungewear: 45, Knitwear: 40, Denim: 47, Dresses: 55, Outerwear: 32 },
  { week: 'W3', Loungewear: 48, Knitwear: 42, Denim: 49, Dresses: 58, Outerwear: 38 },
  { week: 'W4', Loungewear: 46, Knitwear: 45, Denim: 52, Dresses: 61, Outerwear: 42 },
  { week: 'W5', Loungewear: 50, Knitwear: 48, Denim: 55, Dresses: 64, Outerwear: 48 },
  { week: 'W6', Loungewear: 52, Knitwear: 51, Denim: 58, Dresses: 67, Outerwear: 55 },
  { week: 'W7', Loungewear: 55, Knitwear: 54, Denim: 61, Dresses: 70, Outerwear: 62 },
  { week: 'W8', Loungewear: 58, Knitwear: 57, Denim: 64, Dresses: 73, Outerwear: 68 },
  { week: 'W9', Loungewear: 61, Knitwear: 60, Denim: 67, Dresses: 76, Outerwear: 75 },
  { week: 'W10', Loungewear: 64, Knitwear: 63, Denim: 70, Dresses: 79, Outerwear: 82 },
  { week: 'W11', Loungewear: 67, Knitwear: 66, Denim: 73, Dresses: 82, Outerwear: 88 },
  { week: 'W12', Loungewear: 70, Knitwear: 69, Denim: 76, Dresses: 85, Outerwear: 95 },
];

const styleArchetypes = [
  { name: 'Minimalist Modern', value: 28, description: 'Clean, neutral, timeless', topBrands: ['The Row', 'Lemaire', 'Totême'], priceRange: '$200-500' },
  { name: 'Eclectic Creative', value: 22, description: 'Bold colors, mixed patterns', topBrands: ['Collina Strada', 'Sandy Liang', 'SSENSE Exclusive'], priceRange: '$100-300' },
  { name: 'Classic Refined', value: 19, description: 'Polished, traditional, elegant', topBrands: ['Khaite', 'Reformation', 'Self-Portrait'], priceRange: '$250-600' },
  { name: 'Bold Avant-Garde', value: 16, description: 'Experimental, unconventional', topBrands: ['Jacquemus', 'Atelier New Regime', 'Deiji Studios'], priceRange: '$150-450' },
  { name: 'Relaxed Natural', value: 15, description: 'Comfortable, effortless, casual', topBrands: ['Ganni', 'Reformation', 'Nanushka'], priceRange: '$75-250' },
];

const priceData = [
  { range: '$50-100', intent: 62, conversion: 28 },
  { range: '$100-200', intent: 78, conversion: 35 },
  { range: '$200-350', intent: 71, conversion: 42 },
  { range: '$350-500', intent: 58, conversion: 48 },
  { range: '$500+', intent: 42, conversion: 38 },
];

const cityData = [
  { city: 'New York', engagement: 9200, percentChange: 18 },
  { city: 'Los Angeles', engagement: 7650, percentChange: 12 },
  { city: 'London', engagement: 6420, percentChange: 22 },
  { city: 'Toronto', engagement: 5890, percentChange: 15 },
  { city: 'Sydney', engagement: 4230, percentChange: 28 },
];

const ageData = [
  { range: '18-21', users: 8240, percentChange: 24 },
  { range: '21-24', users: 12400, percentChange: 18 },
  { range: '24-27', users: 15680, percentChange: 8 },
  { range: '27-30', users: 7890, percentChange: -2 },
  { range: '30-35', users: 3190, percentChange: 12 },
];

// ============================================================================
// DASHBOARD COMPONENT
// ============================================================================

export default function DataDashboard() {
  const [selectedBrand1, setSelectedBrand1] = useState('Ganni');
  const [selectedBrand2, setSelectedBrand2] = useState('Staud');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const brand1 = useMemo(() => brandData.find(b => b.name === selectedBrand1), [selectedBrand1]);
  const brand2 = useMemo(() => brandData.find(b => b.name === selectedBrand2), [selectedBrand2]);

  const activeUsers = 47200;
  const dailySwipes = 312000;
  const brandsTracked = 65;

  const archetypeColors = {
    'Minimalist Modern': '#E8E8E8',
    'Eclectic Creative': '#FF6B6B',
    'Classic Refined': '#4ECDC4',
    'Bold Avant-Garde': '#FFE66D',
    'Relaxed Natural': '#95E1D3',
  };

  const StatCard = ({ icon: Icon, label, value, change, changeType }) => (
    <div className="bg-gradient-to-br from-slate-800 to-slate-900 rounded-lg p-6 border border-slate-700 hover:border-yellow-600/50 transition-colors">
      <div className="flex items-center justify-between mb-2">
        <span className="text-slate-400 text-sm font-medium">{label}</span>
        <Icon className="w-5 h-5 text-yellow-500" />
      </div>
      <div className="text-2xl font-bold text-white mb-2">{value}</div>
      {change && (
        <div className={`flex items-center text-xs font-medium ${changeType === 'up' ? 'text-green-400' : 'text-red-400'}`}>
          {changeType === 'up' ? <ArrowUpRight className="w-3 h-3 mr-1" /> : <ArrowDownRight className="w-3 h-3 mr-1" />}
          {change}
        </div>
      )}
    </div>
  );

  return (
    <div className="min-h-screen bg-slate-950 text-white">
      {/* ===== HEADER ===== */}
      <header className="sticky top-0 z-50 bg-slate-950 border-b border-slate-800">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-4 flex items-center justify-between">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 bg-yellow-600 rounded-lg flex items-center justify-center font-bold text-slate-950">R</div>
            <div>
              <h1 className="text-2xl font-bold">Rosier Style Intelligence</h1>
              <p className="text-xs text-slate-400">B2B Data Analytics Platform</p>
            </div>
          </div>
          <div className="hidden md:flex items-center gap-4">
            <span className="px-3 py-1 bg-yellow-600/20 text-yellow-500 rounded-full text-xs font-semibold border border-yellow-600/50">DEMO</span>
            <span className="text-xs text-slate-400">Updated 2 hours ago</span>
          </div>
        </div>
      </header>

      {/* ===== MAIN CONTENT ===== */}
      <main className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        {/* Executive Overview */}
        <section>
          <div className="mb-6">
            <h2 className="text-3xl font-bold mb-2">Executive Overview</h2>
            <p className="text-slate-400 text-sm">Real-time fashion intelligence across 65+ brands and 47K+ engaged users</p>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
            <StatCard icon={Users} label="Active Users" value={`${(activeUsers/1000).toFixed(1)}K`} change="+12.3% YoY" changeType="up" />
            <StatCard icon={Zap} label="Daily Swipes" value={`${(dailySwipes/1000).toFixed(0)}K`} change="+8.7% vs last week" changeType="up" />
            <StatCard icon={Package} label="Brands Tracked" value={brandsTracked + '+'} change="+5 this month" changeType="up" />
            <StatCard icon={Calendar} label="Data Freshness" value="Hourly" change="Real-time pipeline" changeType="up" />
          </div>
        </section>

        {/* Brand Heat Map */}
        <section className="bg-slate-900 rounded-lg border border-slate-800 p-6">
          <div className="mb-6">
            <h2 className="text-2xl font-bold mb-2">Brand Heat Map: Top 20 by Affinity</h2>
            <p className="text-slate-400 text-sm">Ranked by user preference signals + engagement velocity</p>
          </div>
          <div className="overflow-x-auto">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-700">
                  <th className="text-left py-3 px-4 text-slate-400 font-semibold">Brand</th>
                  <th className="text-right py-3 px-4 text-slate-400 font-semibold">Affinity Score</th>
                  <th className="text-right py-3 px-4 text-slate-400 font-semibold">Trend</th>
                  <th className="text-right py-3 px-4 text-slate-400 font-semibold">Swipe-to-Save %</th>
                  <th className="text-right py-3 px-4 text-slate-400 font-semibold">Price Sensitivity</th>
                  <th className="text-right py-3 px-4 text-slate-400 font-semibold">Weekly Swipes</th>
                </tr>
              </thead>
              <tbody>
                {brandData.map((brand, idx) => (
                  <tr key={idx} className="border-b border-slate-800 hover:bg-slate-800/50 transition-colors">
                    <td className="py-3 px-4">
                      <div className="flex items-center gap-3">
                        <div className="w-3 h-3 rounded-full" style={{ backgroundColor: brand.color }}></div>
                        <span className="font-medium">{brand.name}</span>
                      </div>
                    </td>
                    <td className="text-right py-3 px-4">
                      <span className="text-lg font-bold text-yellow-500">{brand.affinity.toFixed(1)}</span>
                    </td>
                    <td className="text-right py-3 px-4">
                      <div className="flex items-center justify-end gap-1">
                        {brand.trendDirection === 'up' && <TrendingUp className="w-4 h-4 text-green-400" />}
                        {brand.trendDirection === 'down' && <TrendingDown className="w-4 h-4 text-red-400" />}
                        {brand.trendDirection === 'stable' && <span className="text-slate-500">-</span>}
                        <span className={brand.trendDirection === 'up' ? 'text-green-400' : brand.trendDirection === 'down' ? 'text-red-400' : 'text-slate-400'}>
                          {brand.trendDirection === 'up' && '+8%'}
                          {brand.trendDirection === 'down' && '-3%'}
                          {brand.trendDirection === 'stable' && 'Stable'}
                        </span>
                      </div>
                    </td>
                    <td className="text-right py-3 px-4 text-slate-300">{brand.swipeToSave.toFixed(1)}%</td>
                    <td className="text-right py-3 px-4 text-slate-300">{brand.priceSensitivity}</td>
                    <td className="text-right py-3 px-4 font-medium">{brand.swipes.toLocaleString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        </section>

        {/* Trend Intelligence */}
        <section className="bg-slate-900 rounded-lg border border-slate-800 p-6">
          <div className="mb-6">
            <h2 className="text-2xl font-bold mb-2">12-Week Trend Intelligence</h2>
            <p className="text-slate-400 text-sm">Category performance over time - Outerwear emerging as top trend (+238% WoW)</p>
          </div>
          <div className="h-80">
            <ResponsiveContainer width="100%" height="100%">
              <LineChart data={trendData}>
                <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                <XAxis dataKey="week" stroke="#94A3B8" />
                <YAxis stroke="#94A3B8" />
                <Tooltip
                  contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #475569', borderRadius: '8px', color: '#fff' }}
                  formatter={(value) => [value, '']}
                />
                <Legend />
                <Line type="monotone" dataKey="Loungewear" stroke="#8B5CF6" strokeWidth={2} dot={false} />
                <Line type="monotone" dataKey="Knitwear" stroke="#06B6D4" strokeWidth={2} dot={false} />
                <Line type="monotone" dataKey="Denim" stroke="#F59E0B" strokeWidth={2} dot={false} />
                <Line type="monotone" dataKey="Dresses" stroke="#EC4899" strokeWidth={2} dot={false} />
                <Line type="monotone" dataKey="Outerwear" stroke="#10B981" strokeWidth={3} dot={false} />
              </LineChart>
            </ResponsiveContainer>
          </div>
        </section>

        {/* Style Archetypes & Price Sensitivity */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Style Archetypes */}
          <section className="bg-slate-900 rounded-lg border border-slate-800 p-6">
            <div className="mb-6">
              <h2 className="text-2xl font-bold mb-2">Style Archetype Distribution</h2>
              <p className="text-slate-400 text-sm">User segmentation by aesthetic preference</p>
            </div>
            <div className="h-80 flex items-center justify-center">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={styleArchetypes}
                    cx="50%"
                    cy="50%"
                    innerRadius={60}
                    outerRadius={120}
                    paddingAngle={2}
                    dataKey="value"
                  >
                    {styleArchetypes.map((entry, index) => (
                      <Cell key={`cell-${index}`} fill={archetypeColors[entry.name]} />
                    ))}
                  </Pie>
                  <Tooltip
                    contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #475569', borderRadius: '8px', color: '#fff' }}
                    formatter={(value) => `${value}%`}
                  />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-6 space-y-2">
              {styleArchetypes.map((arch, idx) => (
                <div key={idx} className="text-xs text-slate-300 border border-slate-700 rounded p-2">
                  <div className="flex items-center gap-2 mb-1">
                    <div className="w-2 h-2 rounded-full" style={{ backgroundColor: archetypeColors[arch.name] }}></div>
                    <span className="font-semibold">{arch.name} ({arch.value}%)</span>
                  </div>
                  <p className="text-slate-500 ml-3 text-xs">{arch.priceRange} • Top: {arch.topBrands.slice(0, 2).join(', ')}</p>
                </div>
              ))}
            </div>
          </section>

          {/* Price Sensitivity */}
          <section className="bg-slate-900 rounded-lg border border-slate-800 p-6">
            <div className="mb-6">
              <h2 className="text-2xl font-bold mb-2">Price Sensitivity Analysis</h2>
              <p className="text-slate-400 text-sm">Purchase intent vs. conversion rates by price bracket</p>
            </div>
            <div className="h-80">
              <ResponsiveContainer width="100%" height="100%">
                <BarChart data={priceData}>
                  <CartesianGrid strokeDasharray="3 3" stroke="#334155" />
                  <XAxis dataKey="range" stroke="#94A3B8" />
                  <YAxis stroke="#94A3B8" />
                  <Tooltip
                    contentStyle={{ backgroundColor: '#1e293b', border: '1px solid #475569', borderRadius: '8px', color: '#fff' }}
                    formatter={(value) => `${value}%`}
                  />
                  <Legend />
                  <Bar dataKey="intent" fill="#06B6D4" name="Purchase Intent" radius={[8, 8, 0, 0]} />
                  <Bar dataKey="conversion" fill="#10B981" name="Conversion Rate" radius={[8, 8, 0, 0]} />
                </BarChart>
              </ResponsiveContainer>
            </div>
            <div className="mt-4 bg-slate-800/50 rounded p-3 border border-yellow-600/30">
              <p className="text-xs text-yellow-500 font-semibold mb-1">Sweet Spot Identified:</p>
              <p className="text-xs text-slate-300">$200-350 price range shows 42% conversion with strong intent (71). Recommend inventory allocation here.</p>
            </div>
          </section>
        </div>

        {/* Competitive Brand Comparison */}
        <section className="bg-slate-900 rounded-lg border border-slate-800 p-6">
          <div className="mb-6">
            <h2 className="text-2xl font-bold mb-2">Competitive Brand Insights</h2>
            <p className="text-slate-400 text-sm">Side-by-side comparison of brand performance metrics</p>
          </div>
          <div className="mb-6 grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">Brand 1</label>
              <select
                value={selectedBrand1}
                onChange={(e) => setSelectedBrand1(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded px-3 py-2 text-white text-sm focus:outline-none focus:border-yellow-600"
              >
                {brandData.map((b) => (
                  <option key={b.name} value={b.name}>{b.name}</option>
                ))}
              </select>
            </div>
            <div>
              <label className="block text-sm font-medium text-slate-300 mb-2">Brand 2</label>
              <select
                value={selectedBrand2}
                onChange={(e) => setSelectedBrand2(e.target.value)}
                className="w-full bg-slate-800 border border-slate-700 rounded px-3 py-2 text-white text-sm focus:outline-none focus:border-yellow-600"
              >
                {brandData.map((b) => (
                  <option key={b.name} value={b.name}>{b.name}</option>
                ))}
              </select>
            </div>
          </div>

          {brand1 && brand2 && (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
              {/* Brand 1 */}
              <div className="bg-slate-800/50 rounded-lg p-4 border border-slate-700">
                <h3 className="text-lg font-bold mb-4 flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full" style={{ backgroundColor: brand1.color }}></div>
                  {brand1.name}
                </h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between items-center pb-2 border-b border-slate-700">
                    <span className="text-slate-400">Affinity Score</span>
                    <span className="font-bold text-lg text-yellow-500">{brand1.affinity.toFixed(1)}</span>
                  </div>
                  <div className="flex justify-between items-center pb-2 border-b border-slate-700">
                    <span className="text-slate-400">Weekly Swipes</span>
                    <span className="font-semibold">{brand1.swipes.toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between items-center pb-2 border-b border-slate-700">
                    <span className="text-slate-400">Swipe-to-Save Rate</span>
                    <span className="font-semibold text-green-400">{brand1.swipeToSave.toFixed(1)}%</span>
                  </div>
                  <div className="flex justify-between items-center pb-2 border-b border-slate-700">
                    <span className="text-slate-400">Price Sensitivity</span>
                    <span className="font-semibold text-slate-300">{brand1.priceSensitivity}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-slate-400">Trend Momentum</span>
                    <span className={`font-semibold ${brand1.trendDirection === 'up' ? 'text-green-400' : brand1.trendDirection === 'down' ? 'text-red-400' : 'text-slate-400'}`}>
                      {brand1.trendDirection === 'up' && '↑ +8%'}
                      {brand1.trendDirection === 'down' && '↓ -3%'}
                      {brand1.trendDirection === 'stable' && 'Stable'}
                    </span>
                  </div>
                </div>
              </div>

              {/* Brand 2 */}
              <div className="bg-slate-800/50 rounded-lg p-4 border border-slate-700">
                <h3 className="text-lg font-bold mb-4 flex items-center gap-2">
                  <div className="w-3 h-3 rounded-full" style={{ backgroundColor: brand2.color }}></div>
                  {brand2.name}
                </h3>
                <div className="space-y-3 text-sm">
                  <div className="flex justify-between items-center pb-2 border-b border-slate-700">
                    <span className="text-slate-400">Affinity Score</span>
                    <span className="font-bold text-lg text-yellow-500">{brand2.affinity.toFixed(1)}</span>
                  </div>
                  <div className="flex justify-between items-center pb-2 border-b border-slate-700">
                    <span className="text-slate-400">Weekly Swipes</span>
                    <span className="font-semibold">{brand2.swipes.toLocaleString()}</span>
                  </div>
                  <div className="flex justify-between items-center pb-2 border-b border-slate-700">
                    <span className="text-slate-400">Swipe-to-Save Rate</span>
                    <span className="font-semibold text-green-400">{brand2.swipeToSave.toFixed(1)}%</span>
                  </div>
                  <div className="flex justify-between items-center pb-2 border-b border-slate-700">
                    <span className="text-slate-400">Price Sensitivity</span>
                    <span className="font-semibold text-slate-300">{brand2.priceSensitivity}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="text-slate-400">Trend Momentum</span>
                    <span className={`font-semibold ${brand2.trendDirection === 'up' ? 'text-green-400' : brand2.trendDirection === 'down' ? 'text-red-400' : 'text-slate-400'}`}>
                      {brand2.trendDirection === 'up' && '↑ +8%'}
                      {brand2.trendDirection === 'down' && '↓ -3%'}
                      {brand2.trendDirection === 'stable' && 'Stable'}
                    </span>
                  </div>
                </div>
              </div>
            </div>
          )}
        </section>

        {/* Geographic & Demographic */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          {/* Top Cities */}
          <section className="bg-slate-900 rounded-lg border border-slate-800 p-6">
            <div className="mb-6">
              <h2 className="text-2xl font-bold mb-2">Top Cities by Engagement</h2>
              <p className="text-slate-400 text-sm">Active user concentration and growth</p>
            </div>
            <div className="space-y-3">
              {cityData.map((city, idx) => (
                <div key={idx} className="bg-slate-800/50 rounded p-3 border border-slate-700">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-semibold">{city.city}</span>
                    <span className={`text-sm font-bold ${city.percentChange > 0 ? 'text-green-400' : 'text-red-400'}`}>
                      {city.percentChange > 0 ? '+' : ''}{city.percentChange}% MoM
                    </span>
                  </div>
                  <div className="bg-slate-700 rounded h-2 overflow-hidden">
                    <div
                      className="bg-gradient-to-r from-yellow-600 to-yellow-500 h-full"
                      style={{ width: `${(city.engagement / 10000) * 100}%` }}
                    ></div>
                  </div>
                  <div className="text-xs text-slate-400 mt-1">{city.engagement.toLocaleString()} active users</div>
                </div>
              ))}
            </div>
          </section>

          {/* Age Distribution */}
          <section className="bg-slate-900 rounded-lg border border-slate-800 p-6">
            <div className="mb-6">
              <h2 className="text-2xl font-bold mb-2">Age Distribution (18-35)</h2>
              <p className="text-slate-400 text-sm">User base composition and growth momentum</p>
            </div>
            <div className="space-y-3">
              {ageData.map((age, idx) => (
                <div key={idx} className="bg-slate-800/50 rounded p-3 border border-slate-700">
                  <div className="flex items-center justify-between mb-2">
                    <span className="font-semibold">{age.range}</span>
                    <span className={`text-sm font-bold ${age.percentChange > 0 ? 'text-green-400' : 'text-red-400'}`}>
                      {age.percentChange > 0 ? '+' : ''}{age.percentChange}% YoY
                    </span>
                  </div>
                  <div className="bg-slate-700 rounded h-2 overflow-hidden">
                    <div
                      className="bg-gradient-to-r from-blue-600 to-cyan-500 h-full"
                      style={{ width: `${(age.users / 16000) * 100}%` }}
                    ></div>
                  </div>
                  <div className="text-xs text-slate-400 mt-1">{age.users.toLocaleString()} users</div>
                </div>
              ))}
            </div>
          </section>
        </div>

        {/* Pricing & CTA */}
        <section className="bg-gradient-to-r from-slate-900 via-slate-800 to-slate-900 rounded-lg border border-slate-700 p-8">
          <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
            {/* Pricing Tiers */}
            <div className="bg-slate-900 border border-slate-700 rounded-lg p-6">
              <h3 className="text-lg font-bold mb-2">Starter Plan</h3>
              <div className="text-3xl font-bold text-yellow-500 mb-2">$2,000<span className="text-lg text-slate-400">/mo</span></div>
              <p className="text-slate-400 text-sm mb-4">For individual brands & small teams</p>
              <ul className="space-y-2 text-sm text-slate-300 mb-6">
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Brand-only dashboard
                </li>
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Monthly reports
                </li>
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Email support
                </li>
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Daily data updates
                </li>
              </ul>
              <button className="w-full bg-slate-700 hover:bg-slate-600 text-white py-2 rounded font-semibold transition-colors text-sm">Learn More</button>
            </div>

            <div className="bg-slate-900 border-2 border-yellow-600/50 rounded-lg p-6 relative">
              <span className="absolute -top-3 left-4 bg-yellow-600 text-slate-950 px-3 py-1 rounded-full text-xs font-bold">POPULAR</span>
              <h3 className="text-lg font-bold mb-2">Professional Plan</h3>
              <div className="text-3xl font-bold text-yellow-500 mb-2">$5,000<span className="text-lg text-slate-400">/mo</span></div>
              <p className="text-slate-400 text-sm mb-4">For mid-market retailers & brands</p>
              <ul className="space-y-2 text-sm text-slate-300 mb-6">
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Everything in Starter
                </li>
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Competitor benchmarking
                </li>
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Real-time data (hourly)
                </li>
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Slack integration + weekly office hours
                </li>
              </ul>
              <button className="w-full bg-yellow-600 hover:bg-yellow-500 text-slate-950 py-2 rounded font-bold transition-colors text-sm">Get Started</button>
            </div>

            <div className="bg-slate-900 border border-slate-700 rounded-lg p-6">
              <h3 className="text-lg font-bold mb-2">Enterprise Plan</h3>
              <div className="text-3xl font-bold text-yellow-500 mb-2">Custom<span className="text-lg text-slate-400">/mo</span></div>
              <p className="text-slate-400 text-sm mb-4">For large retailers & conglomerates</p>
              <ul className="space-y-2 text-sm text-slate-300 mb-6">
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Everything in Professional
                </li>
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Custom dashboards & API access
                </li>
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Predictive ML models
                </li>
                <li className="flex items-center gap-2">
                  <span className="text-green-400">✓</span> Dedicated account manager
                </li>
              </ul>
              <button className="w-full bg-slate-700 hover:bg-slate-600 text-white py-2 rounded font-semibold transition-colors text-sm">Contact Sales</button>
            </div>
          </div>

          {/* CTAs */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <button className="flex items-center justify-center gap-2 bg-yellow-600 hover:bg-yellow-500 text-slate-950 font-bold py-3 rounded-lg transition-colors">
              <Download className="w-5 h-5" />
              Request Full Report
            </button>
            <button className="flex items-center justify-center gap-2 border border-yellow-600 text-yellow-500 hover:bg-yellow-600/10 font-bold py-3 rounded-lg transition-colors">
              <Phone className="w-5 h-5" />
              Schedule Demo Call
            </button>
            <button className="flex items-center justify-center gap-2 border border-slate-600 text-slate-300 hover:bg-slate-800 font-bold py-3 rounded-lg transition-colors">
              <Code className="w-5 h-5" />
              API Documentation
            </button>
          </div>
        </section>

        {/* Footer */}
        <footer className="border-t border-slate-800 pt-8 pb-4">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-8 mb-8">
            <div>
              <h4 className="font-bold mb-3">About Rosier</h4>
              <p className="text-xs text-slate-400">Privacy-first fashion analytics powered by real user behavior. Trusted by leading retailers and brands.</p>
            </div>
            <div>
              <h4 className="font-bold mb-3">Product</h4>
              <ul className="space-y-1 text-xs text-slate-400">
                <li className="hover:text-slate-300 cursor-pointer">Style Intelligence Dashboard</li>
                <li className="hover:text-slate-300 cursor-pointer">Trend Reports API</li>
                <li className="hover:text-slate-300 cursor-pointer">Brand Affinity Scoring</li>
              </ul>
            </div>
            <div>
              <h4 className="font-bold mb-3">Legal</h4>
              <ul className="space-y-1 text-xs text-slate-400">
                <li className="hover:text-slate-300 cursor-pointer">Privacy Policy</li>
                <li className="hover:text-slate-300 cursor-pointer">Data Processing Agreement</li>
                <li className="hover:text-slate-300 cursor-pointer">GDPR Compliance</li>
              </ul>
            </div>
          </div>
          <div className="text-center text-xs text-slate-500 border-t border-slate-800 pt-4">
            <p>Rosier Data Intelligence Platform • Built by fashion technologists • DEMO watermark indicates sample data</p>
            <p className="mt-2">All data shown is simulated for demonstration purposes. Real customer data is aggregated and anonymized.</p>
          </div>
        </footer>
      </main>
    </div>
  );
}
